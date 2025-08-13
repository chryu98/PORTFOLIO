// GovGeocodingClient.java
package com.busanbank.card.branch.util;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.Data;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
public class GovGeocodingClient {

    @Value("${gov.service-key}")
    private String serviceKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper om = new ObjectMapper();

    @Data
    public static class LatLng {
        private final double lat; // 위도
        private final double lng; // 경도
    }

    /**
     * vWorld 주소→좌표
     * 1순위: 도로명(type=ROAD), 실패 시 지번(type=PARCEL)
     * 성공 시 WGS84(lat,lng) 반환, 실패 시 null
     */
    public LatLng geocode(String rawAddress) {
        if (rawAddress == null || rawAddress.isBlank()) return null;

        String address = normalizeAddress(rawAddress);

        // 1) 도로명 시도
        LatLng road = requestVWorld(address, "ROAD");
        if (road != null) return road;

        // 2) 지번 시도
        LatLng parcel = requestVWorld(address, "PARCEL");
        if (parcel != null) return parcel;

        // 3) 괄호/부가정보 제거 후 재시도
        String stripped = address.replaceAll("\\s*\\([^\\)]*\\)\\s*", " ").replaceAll("\\s+", " ").trim();
        if (!stripped.equals(address)) {
            LatLng retry = requestVWorld(stripped, "ROAD");
            if (retry != null) return retry;
            return requestVWorld(stripped, "PARCEL");
        }

        log.warn("[vWorld] Geocoding failed. address={}", rawAddress);
        return null;
    }

    private LatLng requestVWorld(String address, String type) {
        try {
            URI uri = UriComponentsBuilder.fromHttpUrl("https://api.vworld.kr/req/address")
                    .queryParam("service", "address")
                    .queryParam("request", "getCoord")
                    .queryParam("version", "2.0")
                    .queryParam("crs", "EPSG:4326")
                    .queryParam("address", address)     // 한글/공백 포함 → 아래 encode에서 처리
                    .queryParam("type", type)           // ROAD | PARCEL
                    .queryParam("key", serviceKey)
                    .encode(StandardCharsets.UTF_8)     // ✅ 반드시 추가
                    .build()
                    .toUri();                           // ✅ 문자열이 아닌 URI로 바로 받기

            HttpHeaders headers = new HttpHeaders();
            headers.setAccept(java.util.List.of(MediaType.APPLICATION_JSON));
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<String> res = restTemplate.exchange(uri, HttpMethod.GET, entity, String.class);

            if (!res.getStatusCode().is2xxSuccessful() || res.getBody() == null) {
                log.warn("[vWorld] HTTP {}", res.getStatusCode());
                return null;
            }

            JsonNode root = om.readTree(res.getBody());
            JsonNode resp = root.path("response");
            String status = resp.path("status").asText("");
            if (!"OK".equalsIgnoreCase(status)) {
                String errMsg = resp.path("error").path("message").asText("");
                log.warn("[vWorld] status={}, message={}, address={}, type={}", status, errMsg, address, type);
                return null;
            }

            JsonNode result = resp.path("result");
            JsonNode first = result.isArray() ? (result.size() > 0 ? result.get(0) : null) : result;
            if (first == null) return null;

            JsonNode point = first.path("point");
            String xStr = point.path("x").asText(null); // 경도
            String yStr = point.path("y").asText(null); // 위도
            if (xStr == null || yStr == null) return null;

            double lng = Double.parseDouble(xStr);
            double lat = Double.parseDouble(yStr);
            return new LatLng(lat, lng);

        } catch (Exception e) {
            log.error("[vWorld] exception: {}", e.getMessage(), e);
            return null;
        }
    }


    /** 주소 전처리(불필요 공백 정리 등) */
    private String normalizeAddress(String s) {
        return s.replaceAll("\\s+", " ").trim();
    }
}

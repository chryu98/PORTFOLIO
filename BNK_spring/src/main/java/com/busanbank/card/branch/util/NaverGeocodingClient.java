package com.busanbank.card.branch.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class NaverGeocodingClient {

    @Value("${gov.service-key}")
    private String serviceKey;

    private final RestTemplate restTemplate = new RestTemplate();

    public LatLng geocode(String address) {
        String url = "https://www.juso.go.kr/addrlink/addrLinkApi.do";

        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(url)
            .queryParam("confmKey", serviceKey)
            .queryParam("currentPage", 1)
            .queryParam("countPerPage", 1)
            .queryParam("keyword", address)
            .queryParam("resultType", "json");

        ResponseEntity<JsonNode> response = restTemplate.getForEntity(builder.toUriString(), JsonNode.class);
        JsonNode body = response.getBody();

        if (body != null && body.has("results")) {
            JsonNode results = body.get("results");
            if (results.has("juso") && results.get("juso").size() > 0) {
                JsonNode first = results.get("juso").get(0);
                // 국토부 API에서 entX = 경도 (lng), entY = 위도 (lat)
                double lng = first.get("entX").asDouble();
                double lat = first.get("entY").asDouble();
                return new LatLng(lat, lng);
            }
        }

        return null;
    }

    public static class LatLng {
        private final double lat;
        private final double lng;

        public LatLng(double lat, double lng) {
            this.lat = lat;
            this.lng = lng;
        }

        public double getLat() { return lat; }
        public double getLng() { return lng; }
    }
}

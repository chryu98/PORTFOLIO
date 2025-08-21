package com.busanbank.card.admin.controller;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.dto.KpiDto;
import com.busanbank.card.admin.dto.StatDto;
import com.busanbank.card.admin.dto.DemogRow;
import com.busanbank.card.admin.service.AdminReviewReportService;

@RestController
public class AdminReviewReportController {

    private final AdminReviewReportService service;

    public AdminReviewReportController(AdminReviewReportService service) {
        this.service = service;
    }

    @GetMapping("/admin/api/review-report/kpi")
    public KpiDto kpi(@RequestParam("startDt") String startDt,
                      @RequestParam("endDt")   String endDt) {
        return service.kpi(startDt, endDt);
    }

    @GetMapping("/admin/api/review-report/trends")
    public Map<String, List<StatDto>> trends(@RequestParam("startDt") String startDt,
                                             @RequestParam("endDt")   String endDt) {
        return service.trends(startDt, endDt);
    }

    @GetMapping("/admin/api/review-report/products")
    public List<StatDto> productStats(@RequestParam("startDt") String startDt,
                                      @RequestParam("endDt")   String endDt) {
        return service.productStats(startDt, endDt);
    }

    /** 프론트 호환을 위해 엔드포인트는 유지하되 creditKind만 반환 */
    @GetMapping("/admin/api/review-report/breakdowns")
    public Map<String, List<StatDto>> breakdowns(@RequestParam("startDt") String startDt,
                                                 @RequestParam("endDt")   String endDt) {
        return service.breakdowns(startDt, endDt); // flags 제거됨
    }

    /** 인구통계 */
    @GetMapping("/admin/api/review-report/demography")
    public Map<String, List<DemogRow>> demography(@RequestParam("startDt") String startDt,
                                                  @RequestParam("endDt")   String endDt) {
        return service.demography(startDt, endDt);
    }
    /** 카드 이미지 프록시 (CORS 회피용) */
    @GetMapping("/admin/proxy-img")
    public ResponseEntity<byte[]> proxyImg(@RequestParam("url") String url) {
        HttpURLConnection conn = null;
        try {
            URL u = new URL(url);
            conn = (HttpURLConnection) u.openConnection();
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(7000);
            conn.setInstanceFollowRedirects(true);
            conn.setRequestProperty("User-Agent",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
                "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36");
            conn.setRequestProperty("Referer", u.getProtocol() + "://" + u.getHost() + "/");

            int code = conn.getResponseCode();
            if (code != HttpURLConnection.HTTP_OK) {
                return ResponseEntity.status(code).build();
            }

            String ctype = conn.getContentType();
            if (ctype == null || !ctype.startsWith("image/")) {
                return ResponseEntity.status(HttpStatus.BAD_GATEWAY).build();
            }

            byte[] body;
            try (InputStream in = conn.getInputStream()) {
                body = in.readAllBytes();
            }

            return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(ctype))
                .cacheControl(CacheControl.maxAge(1, TimeUnit.HOURS).cachePublic())
                .body(body);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).build();
        } finally {
            if (conn != null) conn.disconnect();
        }
    }
}

package com.busanbank.card.feedback.service;

import com.busanbank.card.feedback.dto.AnalysisUpdateReq;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Component
public class FeedbackAnalysisClient {

    @Value("${analysis.base-url}")
    private String baseUrl;

    private final RestTemplate rt = new RestTemplate();

    public AnalysisUpdateReq analyze(Long feedbackNo, String comment, Integer rating) {
        String url = baseUrl + "/analyze";   // 하나의 앱으로 통일 (8000)
        Map<String, Object> body = Map.of(
                "feedback_no", feedbackNo,
                "text", comment,
                "rating", rating
        );
        ResponseEntity<Map> resp = rt.postForEntity(url, body, Map.class);
        Map data = resp.getBody();

        if (data == null) throw new IllegalStateException("Empty analysis response");

        String label = (String) data.get("label");
        Double score = data.get("score") == null ? null : ((Number) data.get("score")).doubleValue();
        List<String> keywords = (List<String>) data.get("keywords");
        boolean inconsistency = data.get("inconsistency") != null && (Boolean) data.get("inconsistency");
        String reason = (String) data.get("reason");

        return new AnalysisUpdateReq(feedbackNo, label, score, keywords, inconsistency, reason);
    }
}

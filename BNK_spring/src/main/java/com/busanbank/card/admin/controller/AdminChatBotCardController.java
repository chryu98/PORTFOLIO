package com.busanbank.card.admin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;
import org.json.JSONObject;

@RestController
@RequestMapping("/admin/cardbot")
public class AdminChatBotCardController {

    private final String FASTAPI_BASE_URL = "http://localhost:8000";
    private final RestTemplate restTemplate;

    @Autowired
    public AdminChatBotCardController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @PostMapping("/train")
    public String trainCardModel() {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<String> entity = new HttpEntity<>(headers);

            ResponseEntity<String> response = restTemplate.postForEntity(
                FASTAPI_BASE_URL + "/train-card", entity, String.class);

            return "FastAPI 응답: " + response.getBody();
        } catch (Exception e) {
            return "FastAPI 호출 실패: " + e.getMessage();
        }
    }

    @GetMapping("/last-trained")
    public String getLastTrainedTime() {
        String url = FASTAPI_BASE_URL + "/train-card/time";

        try {
            String response = restTemplate.getForObject(url, String.class);
            JSONObject json = new JSONObject(response); // JSON 파싱
            String time = json.getString("last_trained");
            return "최근 학습 시각: " + time;
        } catch (Exception e) {
            return "FastAPI 호출 실패: " + e.getMessage();
        }
    }
}

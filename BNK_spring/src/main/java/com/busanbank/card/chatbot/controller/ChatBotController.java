package com.busanbank.card.chatbot.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/user/card")  // 원하는 대로 URL 경로 변경
public class ChatBotController {

    @PostMapping("/chatbot")  // POST: /user/card/chatbot
    public ResponseEntity<String> askQuestion(@RequestBody Map<String, String> payload) {
        String question = payload.get("question");

        if (question == null || question.trim().isEmpty()) {
            return ResponseEntity.badRequest().body("질문이 비어 있습니다.");
        }

        RestTemplate rest = new RestTemplate();
        Map<String, String> req = new HashMap<>();
        req.put("question", question);

        try {
            Map<String, String> response = rest.postForObject(
                "http://localhost:8000/card-chat",  // FastAPI 카드 챗봇 엔드포인트로 변경
                req,
                Map.class
            );

            String answer = response.get("answer");
            return ResponseEntity.ok(answer);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("챗봇 응답 실패: " + e.getMessage());
        }
    }
}

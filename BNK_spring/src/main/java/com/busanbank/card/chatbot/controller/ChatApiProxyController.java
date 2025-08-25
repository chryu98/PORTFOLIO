// proxy controller
package com.busanbank.card.chatbot.controller;

import lombok.RequiredArgsConstructor;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ChatApiProxyController {


    private final @Qualifier("chatWebClient") WebClient chatWebClient;

    @PostMapping("/ask")
    public Map<String, Object> ask(@RequestBody Map<String, String> body) {
        return chatWebClient.post()
                .uri("/ask")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .timeout(Duration.ofSeconds(15))
                .onErrorReturn(Map.of("answer", "서버 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요."))
                .block(Duration.ofSeconds(16)); // MVC이므로 block으로 변환
    }
}

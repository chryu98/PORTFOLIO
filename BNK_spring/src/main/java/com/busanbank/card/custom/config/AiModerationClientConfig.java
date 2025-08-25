package com.busanbank.card.custom.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

@Configuration
public class AiModerationClientConfig {

    // application.yml(or properties) 키: moderation.base-url
    @Value("${moderation.base-url}")
    private String moderationBaseUrl;


    @Bean("aiModerationWebClient")
    public WebClient aiModerationWebClient() {
        HttpClient httpClient = HttpClient.create();
        return WebClient.builder()
                .baseUrl(moderationBaseUrl) // 예: http://192.168.0.5:8001
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .build();
    }
}

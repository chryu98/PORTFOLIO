// config
package com.busanbank.card.chatbot.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class ChatWebClientConfig {
    @Bean
    WebClient chatWebClient(@Value("${chatbot.python.base-url}") String baseUrl) {
        return WebClient.builder()
                .baseUrl(baseUrl) // ex) http://192.168.0.5:8000
                .build();
    }
}

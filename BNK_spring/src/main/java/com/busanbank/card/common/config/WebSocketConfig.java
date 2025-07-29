package com.busanbank.card.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic");  // 메시지 구독 경로
        config.setApplicationDestinationPrefixes("/app");  // 클라이언트 송신 경로
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/chat")  // 웹소켓 연결 엔드포인트
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
}

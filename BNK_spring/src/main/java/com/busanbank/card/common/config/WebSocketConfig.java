// com.busanbank.card.common.config.WebSocketConfig
package com.busanbank.card.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.*;
import org.springframework.web.socket.server.support.HttpSessionHandshakeInterceptor;

import com.busanbank.card.common.websocket.StompAuthChannelInterceptor;
import lombok.RequiredArgsConstructor;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final StompAuthChannelInterceptor stompAuthChannelInterceptor;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // HTTP 세션 → WS 세션 복사
        registry.addEndpoint("/ws/chat")
                .setAllowedOriginPatterns("*")
                .addInterceptors(new HttpSessionHandshakeInterceptor());

        registry.addEndpoint("/ws/chat")
                .setAllowedOriginPatterns("*")
                .addInterceptors(new HttpSessionHandshakeInterceptor())
                .withSockJS()
                .setSessionCookieNeeded(false);
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(stompAuthChannelInterceptor);
    }

    @Override
    public void configureWebSocketTransport(WebSocketTransportRegistration registry) {
        registry.setMessageSizeLimit(512 * 1024);
        registry.setSendBufferSizeLimit(1024 * 1024);
        registry.setSendTimeLimit(20_000);
    }
}

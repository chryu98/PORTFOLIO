// src/main/java/com/busanbank/card/push/ws/WebSocketConfig.java
package com.busanbank.card.push.ws;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class PushWsConfig implements WebSocketConfigurer {
  private final PushWebSocketHandler handler;

  @Override
  public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
    registry.addHandler(handler, "/ws/push")
            .setAllowedOrigins("*"); // 운영은 도메인 제한 권장
  }
}

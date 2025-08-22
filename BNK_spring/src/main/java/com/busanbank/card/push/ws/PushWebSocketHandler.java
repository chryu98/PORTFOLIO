// src/main/java/com/busanbank/card/push/ws/PushWebSocketHandler.java
package com.busanbank.card.push.ws;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;

@Component
@RequiredArgsConstructor
public class PushWebSocketHandler extends TextWebSocketHandler {
  private final PushSessionRegistry registry;

  @Override
  public void afterConnectionEstablished(WebSocketSession session) throws Exception {
    Long memberNo = resolveMemberNo(session.getUri());
    if (memberNo == null) { session.close(CloseStatus.BAD_DATA); return; }
    registry.add(memberNo, session);
  }

  @Override
  public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
    cleanup(session);
  }

  @Override
  public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
    cleanup(session);
  }

  private void cleanup(WebSocketSession session) {
    Long memberNo = resolveMemberNo(session.getUri());
    if (memberNo != null) registry.remove(memberNo, session);
  }

  private Long resolveMemberNo(URI uri) {
    if (uri == null || uri.getQuery() == null) return null;
    for (String kv : uri.getQuery().split("&")) {
      var p = kv.split("=", 2);
      if (p.length == 2 && p[0].equals("memberNo")) {
        try { return Long.parseLong(p[1]); } catch (Exception ignore) {}
      }
    }
    return null;
  }
}

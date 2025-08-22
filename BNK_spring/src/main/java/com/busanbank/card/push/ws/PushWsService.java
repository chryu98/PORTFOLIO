// src/main/java/com/busanbank/card/push/ws/PushWsService.java
package com.busanbank.card.push.ws;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.*;

import java.io.IOException;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PushWsService {
  private final PushSessionRegistry registry;
  private final ObjectMapper om = new ObjectMapper();

  public void sendToMembers(Collection<Long> memberNos, String title, String content) {
    var payload = Map.of("title", title, "content", content);
    String json;
    try { json = om.writeValueAsString(payload); }
    catch (Exception e) { json = "{\"title\":\""+escape(title)+"\",\"content\":\""+escape(content)+"\"}"; }

    for (Long no : memberNos) {
      for (WebSocketSession s : new ArrayList<>(registry.get(no))) {
        if (!s.isOpen()) { registry.remove(no, s); continue; }
        try {
          s.sendMessage(new TextMessage(json));
        } catch (IOException ex) {
          try { s.close(); } catch (Exception ignore) {}
          registry.remove(no, s);
        }
      }
    }
  }

  private String escape(String s) { return s.replace("\\","\\\\").replace("\"","\\\""); }
}

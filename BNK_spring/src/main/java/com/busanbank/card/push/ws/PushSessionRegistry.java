// src/main/java/com/busanbank/card/push/ws/PushSessionRegistry.java
package com.busanbank.card.push.ws;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketSession;

import java.util.*;
import java.util.concurrent.*;

@Component
public class PushSessionRegistry {
  private final ConcurrentMap<Long, Set<WebSocketSession>> map = new ConcurrentHashMap<>();

  public void add(long memberNo, WebSocketSession s) {
    map.computeIfAbsent(memberNo, k -> ConcurrentHashMap.newKeySet()).add(s);
  }

  public void remove(long memberNo, WebSocketSession s) {
    var set = map.get(memberNo);
    if (set != null) {
      set.remove(s);
      if (set.isEmpty()) map.remove(memberNo);
    }
  }

  public Set<WebSocketSession> get(long memberNo) {
    return map.getOrDefault(memberNo, Set.of());
  }

  public Map<Long, Set<WebSocketSession>> snapshot() {
    return Map.copyOf(map);
  }
}

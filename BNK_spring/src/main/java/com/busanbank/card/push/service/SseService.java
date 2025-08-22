package com.busanbank.card.push.service;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.*;
import java.util.concurrent.*;

@Service
public class SseService {
  private final ConcurrentMap<Long, Set<SseEmitter>> emitters = new ConcurrentHashMap<>();

  public SseEmitter subscribe(long memberNo) {
    SseEmitter e = new SseEmitter(0L); // 무제한 타임아웃(인프라 타임아웃은 별도 설정)
    emitters.computeIfAbsent(memberNo, k -> ConcurrentHashMap.newKeySet()).add(e);

    e.onCompletion(() -> cleanup(memberNo, e));
    e.onTimeout(() -> cleanup(memberNo, e));
    e.onError(ex -> cleanup(memberNo, e));

    try { e.send(SseEmitter.event().name("ping").data("ok")); } catch (Exception ignore) {}
    return e;
  }

  public void sendToMembers(Collection<Long> memberNos, String title, String content) {
    for (Long no : memberNos) {
      Set<SseEmitter> set = emitters.getOrDefault(no, Set.of());
      for (SseEmitter e : new ArrayList<>(set)) {
        try {
          e.send(SseEmitter.event().name("push")
              .data(Map.of("title", title, "content", content)));
        } catch (Exception ex) {
          cleanup(no, e);
        }
      }
    }
  }

  private void cleanup(long memberNo, SseEmitter e) {
    Set<SseEmitter> set = emitters.get(memberNo);
    if (set != null) {
      set.remove(e);
      if (set.isEmpty()) emitters.remove(memberNo);
    }
  }
}

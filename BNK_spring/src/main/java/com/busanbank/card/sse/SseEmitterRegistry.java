package com.busanbank.card.sse;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

@Component
public class SseEmitterRegistry {

    private final Map<Long, CopyOnWriteArraySet<SseEmitter>> emitters = new ConcurrentHashMap<>();

    public SseEmitter register(Long memberNo, long timeoutMillis) {
        SseEmitter emitter = new SseEmitter(timeoutMillis);
        emitters.computeIfAbsent(memberNo, k -> new CopyOnWriteArraySet<>()).add(emitter);

        emitter.onCompletion(() -> remove(memberNo, emitter));
        emitter.onTimeout(() -> remove(memberNo, emitter));
        emitter.onError(e -> remove(memberNo, emitter));
        return emitter;
    }

    public void remove(Long memberNo, SseEmitter emitter) {
        var set = emitters.get(memberNo);
        if (set != null) {
            set.remove(emitter);
            if (set.isEmpty()) emitters.remove(memberNo);
        }
    }

    public Set<SseEmitter> getEmitters(Long memberNo) {
        return emitters.getOrDefault(memberNo, new CopyOnWriteArraySet<>());
    }

    public Set<Map.Entry<Long, CopyOnWriteArraySet<SseEmitter>>> all() {
        return emitters.entrySet();
    }

    public void safeSend(SseEmitter emitter, SseEmitter.SseEventBuilder event, Runnable onFail) {
        try {
            emitter.send(event);
        } catch (IOException | IllegalStateException ex) {
            onFail.run(); // 끊긴 연결 정리
        }
    }
}

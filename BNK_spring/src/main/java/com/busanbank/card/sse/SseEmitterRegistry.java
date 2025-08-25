package com.busanbank.card.sse;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import jakarta.annotation.PreDestroy;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

@Component
public class SseEmitterRegistry {

	private final Map<Long, CopyOnWriteArraySet<SseEmitter>> emitters = new ConcurrentHashMap<>();

	
    @PreDestroy
    public void shutdown() {
        emitters.values().forEach(set -> set.forEach(e -> {
            try { e.complete(); } catch (Exception ignore) {}
        }));
        emitters.clear();
    }
    
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
			if (set.isEmpty())
				emitters.remove(memberNo);
		}
	}

	public Set<SseEmitter> getEmitters(Long memberNo) {
		return emitters.getOrDefault(memberNo, new CopyOnWriteArraySet<>());
	}

	public Set<Map.Entry<Long, CopyOnWriteArraySet<SseEmitter>>> all() {
		return emitters.entrySet();
	}

	public boolean safeSend(SseEmitter emitter, SseEmitter.SseEventBuilder event, Runnable onDrop) {
		try {
			emitter.send(event);
			return true;
		} catch (Exception ex) { // IOException, ClientAbortException, EOFException 등 포함
			try {
				emitter.complete();
			} catch (Exception ignore) {
			}
			try {
				onDrop.run();
			} catch (Exception ignore) {
			}
// 여기서 예외를 '먹어야' DispatcherServlet까지 안 올라갑니다.
			return false;
		}
	}

}

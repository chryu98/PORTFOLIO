// src/main/java/com/busanbank/card/push/sse/PushSseController.java
package com.busanbank.card.push.sse;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class PushSseController {

    // 연결된 클라이언트 (memberNo → emitter)
    private final Map<Long, SseEmitter> clients = new ConcurrentHashMap<>();

    /** 구독 */
    public SseEmitter subscribe(Long memberNo) {
        SseEmitter emitter = new SseEmitter(0L); // 무제한 타임아웃
        clients.put(memberNo, emitter);

        emitter.onCompletion(() -> clients.remove(memberNo));
        emitter.onTimeout(() -> clients.remove(memberNo));
        emitter.onError((e) -> clients.remove(memberNo));

        log.info("[SSE] 구독 시작: memberNo={}", memberNo);
        try {
            emitter.send(SseEmitter.event().name("INIT").data("connected"));
        } catch (IOException ignored) {}
        return emitter;
    }

    /** 특정 사용자 발송 */
    public void sendToUser(Long memberNo, String title, String content) {
        SseEmitter emitter = clients.get(memberNo);
        if (emitter != null) {
            try {
                emitter.send(SseEmitter.event()
                        .name("PUSH")
                        .data(Map.of("title", title, "content", content)));
                log.info("[SSE] 발송 성공 → memberNo={} title={}", memberNo, title);
            } catch (IOException e) {
                clients.remove(memberNo);
                log.warn("[SSE] 발송 실패 → memberNo={}", memberNo, e);
            }
        } else {
            log.warn("[SSE] 대상 없음 → memberNo={}", memberNo);
        }
    }

    /** 전체 발송 */
    public void sendToAll(String title, String content) {
        clients.forEach((memberNo, emitter) -> {
            try {
                emitter.send(SseEmitter.event()
                        .name("PUSH")
                        .data(Map.of("title", title, "content", content)));
                log.info("[SSE] 전체 발송 → memberNo={} title={}", memberNo, title);
            } catch (IOException e) {
                clients.remove(memberNo);
                log.warn("[SSE] 전체 발송 실패 → memberNo={}", memberNo, e);
            }
        });
    }
}

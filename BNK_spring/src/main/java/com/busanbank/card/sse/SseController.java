package com.busanbank.card.sse;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/sse")
public class SseController {

    private final SseEmitterRegistry registry;

    public SseController(SseEmitterRegistry registry) {
        this.registry = registry;
    }

    // 예: GET /api/sse/stream?memberNo=6
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(@RequestParam Long memberNo,
                             @RequestHeader(name = "Last-Event-ID", required = false) String lastEventId) {
        SseEmitter emitter = registry.register(memberNo, 60L * 60 * 1000); // 1시간
        // 연결 확인용 이벤트
        registry.safeSend(emitter, SseEmitter.event().name("ready").data("ok"), () -> {});
        // 필요하면 여기서 미전송분 밀어주기 로직을 붙일 수 있음
        return emitter;
    }
}

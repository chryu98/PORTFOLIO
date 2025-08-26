package com.busanbank.card.sse;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.busanbank.card.cardapply.config.JwtTokenProvider;

@RestController
@RequestMapping("/api/sse")
@CrossOrigin(origins = "*")
public class SseController {

    private final SseEmitterRegistry registry;
    private final JwtTokenProvider jwtTokenProvider;
    private final SseEventStore store;

    public SseController(SseEmitterRegistry registry, JwtTokenProvider jwtTokenProvider, SseEventStore store) {
        this.registry = registry;
        this.jwtTokenProvider = jwtTokenProvider;
        this.store = store;
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public ResponseEntity<SseEmitter> stream(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestParam(value = "memberNo", required = false) Long memberNoParam,
            @RequestHeader(name = "Last-Event-ID", required = false) String lastEventId
    ) {
        Long memberNo = memberNoParam;

        if (memberNo == null && authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtTokenProvider.validateToken(token)) {
                Integer no = jwtTokenProvider.getMemberNo(token); // 존재한다고 하셨던 메서드
                if (no != null) memberNo = no.longValue();
            }
        }

        if (memberNo == null) {
            return ResponseEntity.badRequest().build();
        }

        Long memberNoResolved = memberNo; 
        SseEmitter emitter = registry.register(memberNo, 60L * 60 * 1000);
        registry.safeSend(emitter, SseEmitter.event().name("ready").data("ok"), () -> {});

        // 재연결 시 누락분 재전송 (최근 50개 한도)
        for (var se : store.since(memberNo, lastEventId, 50)) {
            registry.safeSend(
                    emitter,
                    SseEmitter.event().id(se.id).name(se.name).data(se.payload),
                    () -> registry.remove(memberNoResolved, emitter)
            );
        }

        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "no-cache")
                .header("X-Accel-Buffering", "no")        // Nginx 등 버퍼링 방지
                .contentType(MediaType.TEXT_EVENT_STREAM)
                .body(emitter);
    }
}

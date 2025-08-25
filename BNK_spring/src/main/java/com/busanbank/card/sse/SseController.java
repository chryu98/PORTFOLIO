package com.busanbank.card.sse;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.busanbank.card.cardapply.config.JwtTokenProvider;

@RestController
@RequestMapping("/api/sse")
@CrossOrigin(origins = "*") // 필요 시
public class SseController {

    private final SseEmitterRegistry registry;
    private final JwtTokenProvider jwtTokenProvider;

    public SseController(SseEmitterRegistry registry, JwtTokenProvider jwtTokenProvider) {
        this.registry = registry;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestParam(value = "memberNo", required = false) Long memberNoParam,
            @RequestHeader(name = "Last-Event-ID", required = false) String lastEventId
    ) {
        Long memberNo = memberNoParam;

        // JWT에서 memberNo 추출(토큰에 넣어두셨으니 이 경로가 편합니다)
        if (memberNo == null && authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtTokenProvider.validateToken(token)) {
                // 예: JwtTokenProvider에 getMemberNo(token) 같은 메서드 하나 추가
                Integer no = jwtTokenProvider.getMemberNo(token);
                if (no != null) memberNo = no.longValue();
            }
        }

        if (memberNo == null) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "memberNo is required"
            );
        }

        SseEmitter emitter = registry.register(memberNo, 60L * 60 * 1000);
        registry.safeSend(emitter, SseEmitter.event().name("ready").data("ok"), () -> {});
        return emitter;
    }
}


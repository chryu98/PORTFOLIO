package com.busanbank.card.push.controller;

import com.busanbank.card.push.service.SseService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import jakarta.servlet.http.HttpServletResponse;

@RestController
@RequiredArgsConstructor
public class SseController {
  private final SseService sse;

  // 데모: memberNo 쿼리로 받음. 실서비스에선 인증(JWT) 후 서버에서 식별하세요.
  @GetMapping(value="/sse/subscribe", produces="text/event-stream")
  public SseEmitter subscribe(@RequestParam long memberNo, HttpServletResponse resp) {
    resp.setHeader("Cache-Control", "no-cache");
    resp.setHeader("X-Accel-Buffering", "no"); // Nginx 사용 시 버퍼링 방지
    return sse.subscribe(memberNo);
  }
}

// src/main/java/com/busanbank/card/push/controller/AdminPushController.java
package com.busanbank.card.push.controller;

import com.busanbank.card.push.dto.PushDto;
import com.busanbank.card.push.service.PushService;
import com.busanbank.card.push.sse.PushSseController;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/admin/push")
@RequiredArgsConstructor
public class AdminPushController {

    private final PushSseController sseController;
    private final PushService pushService;

    /** SSE 구독 */
    @GetMapping("/subscribe")
    public SseEmitter subscribe(@RequestParam Long memberNo) {
        return sseController.subscribe(memberNo);
    }

    /** 전체 발송 */
    @PostMapping("/send")
    public Map<String, Object> sendAll(@RequestBody Map<String, Object> body) {
        String title = (String) body.get("title");
        String content = (String) body.get("content");

        // DB 저장
        PushDto dto = new PushDto();
        dto.setTitle(title);
        dto.setContent(content);
        dto.setTargetType("ALL");
        dto.setCreatedBy("admin");
        pushService.save(dto);

        // SSE 전송
        sseController.sendToAll(title, content);

        return Map.of("result", "ok", "pushNo", dto.getPushNo());
    }

    /** 특정 사용자 발송 */
    @PostMapping("/send/user/{memberNo}")
    public Map<String, Object> sendToUser(@PathVariable Long memberNo,
                                          @RequestBody Map<String, Object> body) {
        String title = (String) body.get("title");
        String content = (String) body.get("content");

        // DB 저장
        PushDto dto = new PushDto();
        dto.setTitle(title);
        dto.setContent(content);
        dto.setTargetType("MEMBER_LIST");
        dto.setCreatedBy("admin");
        pushService.save(dto);

        // SSE 전송
        sseController.sendToUser(memberNo, title, content);

        return Map.of("result", "ok", "pushNo", dto.getPushNo());
    }
}

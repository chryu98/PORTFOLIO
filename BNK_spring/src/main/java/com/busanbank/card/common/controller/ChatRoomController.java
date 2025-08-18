// package com.busanbank.card.common.controller;
package com.busanbank.card.common.controller;

import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/chat")
public class ChatRoomController {

    private final ChatService chatService;

    // 방 생성/가져오기: 헤더 X-Member-No 를 명시적으로 받기
    @PostMapping("/room/open")
    public ResponseEntity<Map<String, Object>> openRoom(
            @RequestHeader(name = "X-Member-No") Long memberNo
    ) {
        Long roomId = chatService.createOrGetRoom(memberNo);
        return ResponseEntity.ok(Map.of("roomId", roomId));
    }

    // 히스토리: PathVariable 이름 명시
    @GetMapping("/room/{roomId}/history")
    public ResponseEntity<List<ChatMessageDto>> history(
            @PathVariable("roomId") Long roomId
    ) {
        List<ChatMessageDto> messages = chatService.getMessages(roomId);
        return ResponseEntity.ok(messages);
    }

    // (선택) 최신 오픈 방 조회가 필요하면
    @GetMapping("/room/latest")
    public ResponseEntity<Map<String, Object>> latestRoom(
            @RequestHeader(name = "X-Member-No") Long memberNo
    ) {
        Long roomId = chatService.findLatestOpenRoomId(memberNo);
        return ResponseEntity.ok(Map.of("roomId", roomId));
    }
}

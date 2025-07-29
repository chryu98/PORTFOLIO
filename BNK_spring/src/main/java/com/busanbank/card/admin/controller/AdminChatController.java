package com.busanbank.card.admin.controller;

import com.busanbank.card.admin.service.AdminChatService;
import com.busanbank.card.user.dto.ChatRoomDto;
import com.busanbank.card.user.dto.ChatMessageDto;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/chat") // API 전용 Prefix
@RequiredArgsConstructor
public class AdminChatController {

    private final AdminChatService adminChatService;

    // 전체 방 목록 조회
    @GetMapping("/rooms")
    public List<ChatRoomDto> getAllRooms() {
        return adminChatService.getAllRooms();
    }

    // 방 입장 (관리자 할당)
    @PostMapping("/room/{roomId}/enter")
    public void enterRoom(
            @PathVariable("roomId") Long roomId,
            @RequestParam("adminNo") Long adminNo
    ) {
        adminChatService.assignAdmin(roomId, adminNo);
    }

    // 관리자 메시지 전송
    @PostMapping("/message")
    public void sendAdminMessage(@RequestBody ChatMessageDto dto) {
        adminChatService.sendAdminMessage(dto);
    }

    // 메시지 목록 조회
    @GetMapping("/room/{roomId}/messages")
    public List<ChatMessageDto> getMessages(@PathVariable("roomId") Long roomId) {
        return adminChatService.getMessages(roomId);
    }

    // 채팅방 종료
    @PostMapping("/room/{roomId}/close")
    public void closeRoom(@PathVariable("roomId") Long roomId) {
        adminChatService.closeRoom(roomId);
    }
}

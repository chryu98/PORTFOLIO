package com.busanbank.card.user.controller;

import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.dto.ChatRoomDto;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.service.ChatService;

import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/user/chat")
@RequiredArgsConstructor
public class UserChatController {

    private final ChatService chatService;

    
    @GetMapping("/page")
    public String userChatPage() {
        return "user/userChat";
    }

    @GetMapping("/info")
    public ResponseEntity<UserDto> getUserInfo(HttpSession session) {
        Integer memberNoInt = (Integer) session.getAttribute("loginMemberNo");
        if (memberNoInt == null) {
            System.out.println("세션에 memberNo가 없습니다. 로그인 필요.");
            return ResponseEntity.status(401).build();
        }

        Long memberNo = memberNoInt.longValue();

        String username = (String) session.getAttribute("loginUsername");
        String role = (String) session.getAttribute("loginRole");

        System.out.println("========= User Info =========");
        System.out.println("memberNo: " + memberNo);
        System.out.println("username: " + username);
        System.out.println("role: " + role);
        System.out.println("=============================");

        UserDto dto = new UserDto();
        dto.setMemberNo(memberNo.intValue());
        dto.setUsername(username);
        dto.setRole(role);

        return ResponseEntity.ok(dto);
    }


    /**
     * 방 생성
     */
    @PostMapping("/room")
    public ResponseEntity<Long> createOrGetRoom(@RequestParam("memberNo") Long memberNo) {
        Long roomId = chatService.createOrGetRoom(memberNo);
        return ResponseEntity.ok(roomId);
    }


    /**
     * 내 방 정보 조회
     */
    @GetMapping("/room/{roomId}")
    public ResponseEntity<ChatRoomDto> getRoom(@PathVariable("roomId") Long roomId) {
        ChatRoomDto dto = chatService.getRoom(roomId);
        return ResponseEntity.ok(dto);
    }

    /**
     * 메시지 전송
     */
    @PostMapping("/message")
    public ResponseEntity<Void> sendMessage(@RequestBody ChatMessageDto dto) {
        chatService.sendMessage(dto);
        System.out.println("보내는 메시지 확인: " + dto);

        return ResponseEntity.ok().build();
    }

    @GetMapping("/room/{roomId}/messages")
    public ResponseEntity<List<ChatMessageDto>> getUserMessages(@PathVariable("roomId") Long roomId) {
        System.out.println("========= getUserMessages =========");
        System.out.println("roomId = " + roomId);
        List<ChatMessageDto> list = chatService.getMessages(roomId);
        System.out.println("조회된 메시지 수 = " + list.size());
        return ResponseEntity.ok(list);
    }


    @GetMapping("/my-room")
    public ResponseEntity<Long> getMyRoomId(HttpSession session) {
        Integer memberNoInt = (Integer) session.getAttribute("loginMemberNo");
        if (memberNoInt == null) {
            return ResponseEntity.status(401).build();
        }
        Long memberNo = memberNoInt.longValue();
        Long existing = chatService.findLatestOpenRoomId(memberNo);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(existing);
    }

    /**
     * 상담사 연결 요청
     */
    @PostMapping("/room/{roomId}/request-admin")
    public ResponseEntity<Void> requestAdmin(@PathVariable("roomId") Long roomId) {
        chatService.requestAdmin(roomId);
        return ResponseEntity.ok().build();
    }
}

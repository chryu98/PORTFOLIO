// com.busanbank.card.user.controller.ChatRestController
package com.busanbank.card.user.controller;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.dto.ChatRoomDto;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatRestController {

    private final ChatService chatService;
    private final IUserDao userDao; // ✅ username → member 조회

    /** 로그인 사용자의 열려있는 최신 방 가져오거나 생성 */
    @GetMapping("/room/me")
    public ChatRoomDto getOrCreateMyRoom(Principal principal) {
        final Long memberNo = resolveMemberNo(principal);
        final Long roomId   = chatService.createOrGetRoom(memberNo);
        final ChatRoomDto room = chatService.getRoom(roomId);
        if (room == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "채팅방을 찾을 수 없습니다.");
        return room;
    }

    /** 특정 방의 전체 메시지(오래된→최신) */
    @GetMapping("/messages/{roomId}")
    public List<ChatMessageDto> getAllMessages(@PathVariable Long roomId, Principal principal) {
        final Long memberNo = resolveMemberNo(principal);
        validateRoomAccess(memberNo, roomId); // 접근권한 체크 (사용자 or 관리자)
        return chatService.getMessages(roomId); // ASC 정렬로 전체 반환 (매퍼 정렬 확인)
    }

    // ===================== 내부 헬퍼 =====================

    /** Principal(username) → memberNo 매핑 (IUserDao 활용) */
    private Long resolveMemberNo(Principal principal) {
        if (principal == null || principal.getName() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "인증 정보가 없습니다.");
        }
        final String username = principal.getName();
        final UserDto user = userDao.findByUsername(username);
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "사용자를 찾을 수 없습니다.");
        }
        // IUserDao는 Integer memberNo를 반환하므로 Long으로 변환
        final Integer memberNo = user.getMemberNo(); // 필드명은 UserDto에 맞게
        if (memberNo == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "회원번호가 없습니다.");
        }
        return memberNo.longValue();
    }

    /** 방 접근권한: 방의 memberNo와 동일하거나, 관리자(ROLE_ADMIN)면 허용 */
    private void validateRoomAccess(Long myMemberNo, Long roomId) {
        final ChatRoomDto room = chatService.getRoom(roomId);
        if (room == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "채팅방을 찾을 수 없습니다.");

        if (myMemberNo.equals(safeLong(room.getMemberNo()))) return; // 내 방이면 OK

        // 관리자 허용 (선택): principal의 role이 ROLE_ADMIN이면 허용
        final UserDto me = userDao.findByMemberNo(myMemberNo.intValue());
        final String role = (me != null && me.getRole() != null) ? me.getRole() : "";
        if ("ROLE_ADMIN".equalsIgnoreCase(role)) return;

        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "해당 채팅방에 접근할 수 없습니다.");
    }

    private Long safeLong(Long v) { return v == null ? -1L : v; }
}

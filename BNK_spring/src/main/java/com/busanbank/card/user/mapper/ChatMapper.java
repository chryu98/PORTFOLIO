package com.busanbank.card.user.mapper;

import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.dto.ChatRoomDto;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ChatMapper {

    void insertChatRoom(ChatRoomDto room);

    Long selectCurrRoomId();

    ChatRoomDto selectChatRoom(Long roomId);

    void insertChatMessage(ChatMessageDto dto);

    void updateRoomLastMsgAt(Long roomId);   // ★ 추가

    void increaseUnreadCount(Long roomId);

    List<ChatMessageDto> selectMessages(Long roomId);

    Long selectRoomIdByMember(Long memberNo);

    Long selectLatestOpenRoomIdByMember(@Param("memberNo") Long memberNo);

    // 관리자용
    List<ChatRoomDto> selectAllRooms();

    void assignAdminToRoom(@Param("roomId") Long roomId,
                           @Param("adminNo") Long adminNo);

    void closeRoom(Long roomId);
}

package com.busanbank.card.admin.mapper;

import com.busanbank.card.user.dto.ChatRoomDto;
import com.busanbank.card.user.dto.ChatMessageDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface AdminChatMapper {

    List<ChatRoomDto> selectAllRooms();

    void assignAdmin(@Param("roomId") Long roomId,
                     @Param("adminNo") Long adminNo);

    void closeRoom(@Param("roomId") Long roomId);

    void insertAdminMessage(ChatMessageDto dto);

    List<ChatMessageDto> selectMessages(@Param("roomId") Long roomId);
    
    void resetUnreadCount(@Param("roomId") Long roomId);
    
 // (선택) 최근 메시지 시간 갱신
    void updateRoomLastMsgAt(@Param("roomId") Long roomId);

}

package com.busanbank.card.admin.service;

import com.busanbank.card.user.dto.ChatRoomDto;
import com.busanbank.card.user.dto.ChatMessageDto;
import java.util.List;

public interface AdminChatService {

    List<ChatRoomDto> getAllRooms();

    void assignAdmin(Long roomId, Long adminNo);

    void closeRoom(Long roomId);

    void sendAdminMessage(ChatMessageDto dto);
    
    List<ChatMessageDto> getMessages(Long roomId);
    
 

}

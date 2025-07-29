package com.busanbank.card.user.service;

import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.dto.ChatRoomDto;

import java.util.List;

public interface ChatService {

    Long createRoom(Long memberNo);

    ChatRoomDto getRoom(Long roomId);

    void sendMessage(ChatMessageDto dto);

    void requestAdmin(Long roomId);
    
    List<ChatMessageDto> getMessages(Long roomId);

    Long createOrGetRoom(Long memberNo);
    //에러확인
    Long findLatestOpenRoomId(Long memberNo);   // 추가
    
}

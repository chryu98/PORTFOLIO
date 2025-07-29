package com.busanbank.card.user.service.impl;

import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.dto.ChatRoomDto;
import com.busanbank.card.user.mapper.ChatMapper;
import com.busanbank.card.user.service.ChatService;
import lombok.RequiredArgsConstructor;

import java.util.List;

import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

    private final ChatMapper chatMapper;

    @Override
    public Long createRoom(Long memberNo) {
        ChatRoomDto room = new ChatRoomDto();
        room.setMemberNo(memberNo);
        chatMapper.insertChatRoom(room);
        System.out.println("roomId = " + room.getRoomId());
        return room.getRoomId();
    }


    @Override
    public Long findLatestOpenRoomId(Long memberNo) {
        return chatMapper.selectLatestOpenRoomIdByMember(memberNo);
    }

    @Override
    public ChatRoomDto getRoom(Long roomId) {
        return chatMapper.selectChatRoom(roomId);
    }

    @Override
    public void sendMessage(ChatMessageDto dto) {
        chatMapper.insertChatMessage(dto);
        chatMapper.updateRoomLastMsgAt(dto.getRoomId()); // ★ 추가
        
        if ("USER".equals(dto.getSenderType())) {
            chatMapper.increaseUnreadCount(dto.getRoomId());
        }
    }

    @Override
    public void requestAdmin(Long roomId) {
        System.out.println("Room [" + roomId + "] 상담사 연결 요청됨.");
    }
    
    @Override
    public List<ChatMessageDto> getMessages(Long roomId) {
        return chatMapper.selectMessages(roomId);
    }
    
    @Override
    public Long createOrGetRoom(Long memberNo) {
        Long roomId = chatMapper.selectRoomIdByMember(memberNo);
        if (roomId != null) {
            System.out.println("기존 방 존재! roomId=" + roomId);
            return roomId;
        }
        // 없으면 새로 생성
        ChatRoomDto room = new ChatRoomDto();
        room.setMemberNo(memberNo);
        chatMapper.insertChatRoom(room);
        System.out.println("새로 생성된 roomId = " + room.getRoomId());
        return room.getRoomId();
    }


}

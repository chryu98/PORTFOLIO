// com.busanbank.card.common.handler.ChatWebSocketController
package com.busanbank.card.common.handler;

import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.service.ChatService;
import lombok.RequiredArgsConstructor;

import java.util.Date;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class ChatWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatService chatService;

    @MessageMapping("/chat.sendMessage") // 클라: /app/chat.sendMessage
    public void sendMessage(ChatMessageDto dto) {
        System.out.println("🔥 WS INBOUND: " + dto);

        // 필드 보정
        if (dto.getSentAt() == null) dto.setSentAt(new Date());
        if (dto.getSenderType() == null) dto.setSenderType("USER");
        if (dto.getSenderId() == null) dto.setSenderId(0L);

        chatService.sendMessage(dto);

        messagingTemplate.convertAndSend("/topic/room/" + dto.getRoomId(), dto);
    }
}

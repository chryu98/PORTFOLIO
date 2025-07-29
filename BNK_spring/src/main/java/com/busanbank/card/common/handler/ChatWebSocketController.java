package com.busanbank.card.common.handler;

import com.busanbank.card.user.dto.ChatMessageDto;
import com.busanbank.card.user.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class ChatWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatService chatService;

    @MessageMapping("/chat.sendMessage")
    public void sendMessage(ChatMessageDto dto) {
        chatService.sendMessage(dto);

        System.out.println("==== WebSocket BROADCAST DTO ====");
        System.out.println(dto);

        messagingTemplate.convertAndSend(
                "/topic/room/" + dto.getRoomId(),
                dto
        );
    }

}

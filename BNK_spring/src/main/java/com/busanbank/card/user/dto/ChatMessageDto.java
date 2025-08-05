package com.busanbank.card.user.dto;

import java.util.Date;

import lombok.Data;

@Data
public class ChatMessageDto {
    private Long roomId;
    private String senderType; // USER / ADMIN
    private Long senderId;
    private String message;
    private Date sentAt; // ← 반드시 추가

}

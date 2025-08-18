package com.busanbank.card.user.dto;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Data;

@Data
public class ChatMessageDto {
    private Long messageId;     // ★ 추가 (MSG_ID 매핑)
    private Long roomId;
    private String senderType;  // USER / ADMIN
    private Long senderId;
    private String message;
    private Date sentAt;
}
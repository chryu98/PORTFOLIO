package com.busanbank.card.user.dto;

import lombok.Data;
import java.util.Date;

@Data
public class ChatRoomDto {
    private Long roomId;
    private Long memberNo;
    private Long adminNo;
    private Integer unreadCount;
    private Date createdAt;
    private Date closedAt;
    private Date lastMessageAt; // ★ 추가
}
// src/main/java/com/busanbank/card/push/dto/PushDto.java
package com.busanbank.card.push.dto;

import lombok.Data;
import java.util.Date;

@Data
public class PushDto {
    private Long pushNo;       // PUSH_NO (자동 증가 PK)
    private String title;      // TITLE (알림 제목)
    private String content;    // CONTENT (알림 본문)
    private String targetType; // TARGET_TYPE ("ALL" or "MEMBER_LIST")
    private String createdBy;  // CREATED_BY (관리자 ID)
    private Date createdAt;    // CREATED_AT (생성 시각)
}

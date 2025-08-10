package com.busanbank.card.card.dto;

import lombok.Data;
import java.util.Date;

@Data
public class CardBehaviorLogDto {
    private Long logNo;           // SEQ에서 자동 증가
    private Long memberNo;
    private Long cardNo;
    private String behaviorType;
    private Date behaviorTime;
    private String deviceType;
    private String userAgent;
    private String ipAddress;
}

package com.busanbank.card.card.dto;

import java.util.Date;

import lombok.Data;

@Data
public class CardApplicationDTO {
    private Long applicationNo;
    private Long memberNo;
    private Long cardNo;
    private Long signNo;
    private String status;         // 신청중, 승인, 반려, 발급완료 등
    private String isCreditCard;   // 'Y' or 'N'
    private Date createdAt;
    private Date approvedAt;

  
}

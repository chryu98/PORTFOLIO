package com.busanbank.card.card.dto;


import lombok.Data;

@Data
public class ApplicationRequestDto {
    private Long memberNo;      // 회원 번호
    private Long cardNo;        // 신청할 카드 번호
    private String isCreditCard; // 'Y' 또는 'N'
}
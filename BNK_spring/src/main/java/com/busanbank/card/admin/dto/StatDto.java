package com.busanbank.card.admin.dto;

import lombok.Data;

/**
 * 범용 통계 로우:
 * - 트렌드: day, cnt
 * - 상품: cardNo, starts, issued, conversionPct
 * - 신용/체크: isCreditCard, starts, issued, conversionPct
 * - 플래그: hasAccountAtKyc, isShortTermMulti, starts, issued, conversionPct
 * - 오래 대기: applicationNo, memberNo, cardNo, daysWaiting
 * (쓰지 않는 필드는 null)
 */
@Data
public class StatDto {
    // 공통/차원
    private String day;                  // 'YYYY-MM-DD' (트렌드)
    private Long cardNo;                 // 상품
    private String isCreditCard;         // 'Y'/'N'
    private String hasAccountAtKyc;      // 'Y'/'N'
    private String isShortTermMulti;     // 'Y'/'N'

    private Long applicationNo;          // 오래 대기
    private Long memberNo;               // 오래 대기

    // 지표
    private Integer cnt;                 // 트렌드 count
    private Integer starts;              // 신청 수
    private Integer issued;              // 발급 수
    private Double conversionPct;        // 전환율(%)
    private Double daysWaiting;          // 대기 일수
    
    private String  cardName;
    private String  cardImg;

}
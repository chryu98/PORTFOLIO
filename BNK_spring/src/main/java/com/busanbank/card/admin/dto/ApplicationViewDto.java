// com.busanbank.card.admin.dto.ApplicationViewDto.java
package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class ApplicationViewDto {
    private Long applicationNo;
    private Long memberNo;
    private Long cardNo;
    private String cardName;       // CARD 테이블에 카드명 컬럼이 있다면
    private String cardUrl;           // CARD.CARD_URL (이미지 경로)
    private String status;         // DRAFT, ISSUED ...
    private String isCreditCard;   // Y/N
    private String hasAccountAtKyc;// Y/N
    private String isShortTermMulti;// Y/N
    private String createdAt;      // 문자열로 내려도 되고, Date로 내려도 됨
    private String updatedAt;
}

package com.busanbank.card.cardapply.dto;

import java.util.Date;

import lombok.Data;

@Data
public class CardApplicationDto {
	
	private Integer applicationNo;     // 신청 PK (시퀀스)
    private Integer memberNo;          // 회원 번호
    private Long cardNo;            // 카드 번호 (상품 ID)
    private String status;             // 신청 상태 (ex: DRAFT)
    private String isCreditCard;       // 신용카드 여부 ('Y'/'N')
    private String hasAccountAtKyc;   // KYC 시점 계좌 보유 여부 ('Y'/'N')
    private String isShortTermMulti;   // 단기 다수 계좌 여부 ('Y'/'N')
    private Date createdAt;            // 생성일
    private Date updatedAt;            // 수정일
    
    private String cardName;
    private String recommendation;
}
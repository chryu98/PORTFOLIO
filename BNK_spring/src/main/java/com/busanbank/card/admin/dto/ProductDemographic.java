package com.busanbank.card.admin.dto;

import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class ProductDemographic {
	private Long cardNo;
    private String cardName;

    private int salesCount;   // ISSUED 건수(판매)

    private int maleCount;    // 남성 판매 건수
    private int femaleCount;  // 여성 판매 건수

    private int age10s;
    private int age20s;
    private int age30s;
    private int age40s;
    private int age50s;
    private int age60s;
}

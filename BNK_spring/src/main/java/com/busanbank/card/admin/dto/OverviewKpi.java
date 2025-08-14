// src/main/java/com/busanbank/card/admin/dto/OverviewKpi.java
package com.busanbank.card.admin.dto;

import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class OverviewKpi {
    private int applies;              // 신청 수
    private int approved;             // 승인 수 (정의: KYC_PASSED, ACCOUNT_CONFIRMED, OPTIONS_SET, ISSUED)
    private int issued;               // 발급완료(판매) 수
    private Double wowIssuedDeltaPct; // 전주 대비 판매 증감률(%) - 서비스에서 계산, null 가능
}

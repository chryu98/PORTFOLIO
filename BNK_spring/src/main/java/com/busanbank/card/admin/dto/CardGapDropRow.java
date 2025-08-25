package com.busanbank.card.admin.dto;

import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class CardGapDropRow {
    private Long   cardNo;
    private String cardName;

    // 구간: fromStep -> toStep (from을 통과한 뒤 to로 못 간 사람 = 이탈)
    private String fromStepCode;    // 기준 단계 코드 (예: CONTACT_INPUT)
    private String fromStepName;    // 기준 단계 명
    private String toStepCode;      // 다음 단계 코드 (예: JOB_INPUT)
    private String toStepName;      // 다음 단계 명
    private Integer toStepOrder;    // 다음 단계 순서

    // 지표(이름을 길게, 명확하게)
    private Long    reachedAtFrom;   // 기준 단계까지 도달한 신청 수
    private Long    reachedAtTo;     // 다음 단계까지 도달한 신청 수
    private Long    droppedBetween;  // 기준→다음 단계 사이에 중단한 신청 수 (= reachedAtFrom - reachedAtTo)
    private Double  dropPct;         // 이탈률(%): droppedBetween / reachedAtFrom * 100
}

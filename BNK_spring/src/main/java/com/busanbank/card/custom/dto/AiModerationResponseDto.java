package com.busanbank.card.custom.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AiModerationResponseDto {
    // 파이썬 응답 매핑
    private String decision;     // ACCEPT | REJECT
    private String reason;       // OK | VIOLENCE_GUN | VIOLENCE_KNIFE ...
    private String label;        // gun | knife | null
    private Double confidence;   // 신뢰도
    private String model;        // yolo+weapons@v1 등
    private Integer inferenceMs; // 추론 소요 시간(ms)
}

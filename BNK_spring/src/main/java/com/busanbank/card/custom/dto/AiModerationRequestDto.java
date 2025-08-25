package com.busanbank.card.custom.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AiModerationRequestDto {
    // 파일 업로드 대신 URL로 보낼 때 사용 (둘 중 하나만 채워서 보냄)
    private String imageUrl;

    // 추적용 메타
    private Long customNo;
    private Long memberNo;
}

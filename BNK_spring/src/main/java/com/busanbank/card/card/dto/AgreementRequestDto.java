package com.busanbank.card.card.dto;

import lombok.Data;
import java.util.List;

@Data
public class AgreementRequestDto {
    private Long applicationNo;         // 신청번호
    private List<Long> termNos;         // 동의한 약관 ID 리스트
}
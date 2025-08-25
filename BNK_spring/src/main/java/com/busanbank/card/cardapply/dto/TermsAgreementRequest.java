package com.busanbank.card.cardapply.dto;

import java.util.List;

import lombok.Data;

@Data
public class TermsAgreementRequest {
    private int memberNo;
    private Long cardNo;
    private List<Long> pdfNos;  // 사용자가 동의한 약관들
    private Long applicationNo;   // ✅ 추가
}

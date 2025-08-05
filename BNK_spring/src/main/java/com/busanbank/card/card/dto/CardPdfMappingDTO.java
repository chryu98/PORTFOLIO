package com.busanbank.card.card.dto;

import lombok.Data;

@Data
public class CardPdfMappingDTO {
    private Long cardNo;
    private Long pdfNo;
    private String isRequired; // 'Y' or 'N'

   
}
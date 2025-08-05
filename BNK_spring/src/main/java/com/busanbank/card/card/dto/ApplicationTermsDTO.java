package com.busanbank.card.card.dto;

import java.util.Date;

import lombok.Data;

@Data
public class ApplicationTermsDTO {
    private Long agreementNo;
    private Long applicationNo;
    private Long termNo;  // = PDF_NO
    private Date agreedAt;

    
}
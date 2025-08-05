package com.busanbank.card.card.dto;

import java.util.Date;

import lombok.Data;

@Data
public class ApplicationSignDTO {
    private Long signNo;
    private Long applicationNo;
    private String agreedText;
    private byte[] signImage;  // 전자 서명 이미지
    private byte[] idImage;    // 주민등록증 이미지
    private Date signedAt;

  
}
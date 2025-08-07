package com.busanbank.card.card.dto;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class SignDto {
    private Long applicationNo;          // 신청번호
    private String agreedText;           // 동의 문구 요약
    private MultipartFile signImage;     // 서명 이미지
    private MultipartFile idImage;       // 신분증 이미지
}
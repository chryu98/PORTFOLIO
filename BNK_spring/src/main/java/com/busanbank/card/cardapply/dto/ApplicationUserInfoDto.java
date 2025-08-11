package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class ApplicationUserInfoDto {
    private int infoNo;
    private int applicationNo;    // 신청번호 (외래키)
    private String name;          // 이름
    private String nameEng;       // 영문 이름
    private String rrnFront;      // 주민번호 앞자리
    private String rrnGender;     // 주민번호 성별코드
    private String rrnTailEnc;    // 주민번호 뒷자리 (암호화된 값)
    private String isExistingAccount; // 'Y' or 'N'
}
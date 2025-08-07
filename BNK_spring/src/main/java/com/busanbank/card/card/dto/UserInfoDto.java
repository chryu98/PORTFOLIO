package com.busanbank.card.card.dto;

import lombok.Data;

@Data
public class UserInfoDto {
    private Long applicationNo;   // 신청번호 (외래키)
    private String name;          // 이름
    private String nameEng;       // 영문 이름
    private String rrnFront;      // 주민번호 앞자리
    private String rrnTailEnc;    // 주민번호 뒷자리 (암호화된 값)
    private String isExistingAccount; // 'Y' or 'N'
}
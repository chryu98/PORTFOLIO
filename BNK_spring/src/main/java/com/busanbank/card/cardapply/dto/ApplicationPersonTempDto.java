package com.busanbank.card.cardapply.dto;

import java.util.Date;

import lombok.Data;

@Data
public class ApplicationPersonTempDto {
    private Integer infoNo;            // 기본정보 PK (시퀀스)
    private Integer applicationNo;     // 연결된 신청 번호 (FK)
    private String name;               // 이름
    private String nameEng;            // 영문 이름 (성 + 이름 합친 문자열)
    private String rrnFront;           // 주민등록번호 앞 6자리
    private String rrnGender;          // 주민등록번호 성별코드 (rrnBack 첫 글자)
    private String rrnTailEnc;         // 암호화된 주민등록번호 뒤 7자리
    private String phone;              // 휴대폰 번호 (필요 시)
    private String email;              // 이메일 (필요 시)
    private String zipCode;            // 우편번호 (필요 시)
    private String address1;           // 기본 주소 (필요 시)
    private String address2;           // 상세 주소 (필요 시)
    private Date createdAt;            // 생성일
}

package com.busanbank.card.cardapply.dto;

import java.util.Date;

import lombok.Data;

@Data
public class CardPaswwordDto {

    private Long cpNo;
    private Long memberNo;
    private Long cardNo;
    private String pinPhc;          // bcrypt 결과("$2b$...") 저장
    private Date createdAt;
    private Date lastModifiedDate;
}

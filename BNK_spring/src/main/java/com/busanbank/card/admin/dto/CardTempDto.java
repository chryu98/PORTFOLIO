package com.busanbank.card.admin.dto;

import java.util.Date;

import lombok.Data;

@Data
public class CardTempDto {
    private Long tempNo;
    private Long cardNo;
    private String cardName;
    private String cardType;
    private String cardBrand;
    private Long viewCount;
    private Long annualFee;
    private String issuedTo;
    private String service;
    private String sService;
    private String cardStatus;
    private String cardUrl;
    private Date cardIssueDate;
    private Date cardDueDate;
    private String cardSlogan;
    private String cardNotice;
    private Date regDate;
    private Date editDate;
    private String status;
    private String perAdmin;
    private String sAdmin;
    private String reason;

}

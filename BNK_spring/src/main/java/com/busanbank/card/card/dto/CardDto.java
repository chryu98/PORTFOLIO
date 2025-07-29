package com.busanbank.card.card.dto;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CardDto {
	private Long cardNo;
    private String cardName;
    private String cardType;
    private String cardBrand;
    private Integer viewCount;
    private Integer annualFee;
    private String issuedTo;
    private String service;
    
    @JsonProperty("sService")
    private String sService;
    
    private String cardStatus;
    private String cardUrl;
    private LocalDate cardIssueDate;
    private LocalDate cardDueDate;
    private String cardSlogan;
    private String cardNotice;
    private LocalDate regDate;
    private LocalDate editDate;
    private String popularImgUrl; 
}

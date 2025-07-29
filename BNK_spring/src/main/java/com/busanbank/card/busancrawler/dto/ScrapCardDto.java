package com.busanbank.card.busancrawler.dto;

import java.time.LocalDate;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ScrapCardDto {
	private Long scCardNo;
    private String scCardUrl;
    private String scCardSlogan;
    private String scCardName;
    private int scAnnualFee;
    private String scSService;
    private LocalDate scDate;
    private String scBenefits;
}
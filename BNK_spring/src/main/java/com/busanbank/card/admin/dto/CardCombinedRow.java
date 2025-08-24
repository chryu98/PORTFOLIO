package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class CardCombinedRow {
	private Integer cardNo;
	private String cardName;
	private String cardImg;
	private Integer startsTemp;
	private Integer confirmed;
	private Double conversionPct;
}
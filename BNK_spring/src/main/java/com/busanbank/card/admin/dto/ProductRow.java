package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class ProductRow {
	private Integer cardNo;
	private String cardName;
	private String cardImg;
	private Integer starts;
	private Integer issued;
	private Double conversionPct;
}
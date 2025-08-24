package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class CreditKindRow {
	private String isCreditCard; // 'Y'/'N'
	private Integer starts;
	private Integer issued;
	private Double conversionPct;
}
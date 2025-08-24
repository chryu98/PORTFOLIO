package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class CardDemogRow {
	private Integer cardNo;
	private String cardName;
	private String ageBand; // '20대' 등
	private String gender; // 'M'/'F'/'U'
	private Integer startsTemp; // 임시
	private Integer confirmed; // 확정(SIGNED)
}
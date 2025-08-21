package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class DemogRow {
	private String ageBand; // "10대 이하","20대","30대","40대","50대","60대+"
	private String gender; // "M","F","U"
	private Integer cnt;
}

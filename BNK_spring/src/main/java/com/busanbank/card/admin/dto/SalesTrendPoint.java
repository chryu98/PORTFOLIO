package com.busanbank.card.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SalesTrendPoint {
	private String date; // YYYY-MM-DD
	private int count; // 신청/판매 건수
}

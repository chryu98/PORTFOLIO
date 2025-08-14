package com.busanbank.card.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductSummary {

	private Long cardNo;
	private String cardName;
	private int applyCount;
	private int approvedCount;
	private int issuedCount;
}

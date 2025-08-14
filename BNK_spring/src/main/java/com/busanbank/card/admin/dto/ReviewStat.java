package com.busanbank.card.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewStat {
	private Long cardNo;
	private String cardName;
	private double avgRating;
	private int reviewCount;
}

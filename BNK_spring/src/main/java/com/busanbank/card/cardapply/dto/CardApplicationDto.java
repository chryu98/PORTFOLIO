package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class CardApplicationDto {

	private int applicationNo;
	private int memberNo;
	private int cardNo;
	private int signNo;
	private char isCreditCard;
	private String createdAt;
	private String approvedAt;
}

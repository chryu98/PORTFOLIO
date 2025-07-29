package com.busanbank.card.user.dto;

import lombok.Data;

@Data
public class TermsAgreementDto {

	private int memberNo;
	private int termNo;
	private String agreedAt;
	private String createdAt;
	private String updatedAt;
}

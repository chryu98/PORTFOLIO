package com.busanbank.card.user.dto;

import lombok.Data;

@Data
public class UserCardDto {

	private Long cardNo;
	private String cardName;
    private String cardUrl;
    private String accountNumber;
    private String status;
}

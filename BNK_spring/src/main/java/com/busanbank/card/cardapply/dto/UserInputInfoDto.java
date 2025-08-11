package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class UserInputInfoDto {
	
	private Long cardNo;
    private String name;
    private String engFirstName;
    private String engLastName;
    private String rrnFront;
    private String rrnBack;
}
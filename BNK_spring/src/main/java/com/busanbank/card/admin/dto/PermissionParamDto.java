package com.busanbank.card.admin.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PermissionParamDto {
	private Long cardNo;
    private String perContent;
    private String admin;
}

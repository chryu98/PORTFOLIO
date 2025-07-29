package com.busanbank.card.user.dto;

import lombok.Data;

@Data
public class UserJoinDto {

	private String username;
	private String password;
	private String passwordCheck;
	private String name;
	private String role;
	
	//주민등록번호
	private String rrnFront;
	private String rrnBack;
	
	//주소
	private String zipCode;
	private String address1;
	private String extraAddress;
	private String address2;
}

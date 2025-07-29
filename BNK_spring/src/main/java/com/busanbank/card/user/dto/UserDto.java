package com.busanbank.card.user.dto;

import lombok.Data;

@Data
public class UserDto {
	
	private int memberNo;
	private String username;
	private String password;
	private String name;	
	private String role;
	
	//주민등록번호
	private String rrnFront;
	private String rrnGender;
	private String rrnTailEnc;
	
	//주소
	private String zipCode;
	private String address1;
	private String address2;
	
}

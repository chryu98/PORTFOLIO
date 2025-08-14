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
	private String rrnFront; //주민번호 앞자리 6개
	private String rrnGender; //성별
	private String rrnTailEnc; //뒷자리 6개 암호화
	
	//주소
	private String zipCode;
	private String address1;
	private String address2;
	
}

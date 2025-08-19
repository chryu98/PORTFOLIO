package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class AddressDto {

	private Integer applicationNo;
	private String zipCode;
	private String address1;
	private String extraAddress;
	private String address2;
	private String addressType;    // 'H' = 집, 'W' = 직장
}

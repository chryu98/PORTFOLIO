package com.busanbank.card.cardapply.dto;

import java.util.Date;

import lombok.Data;

@Data
public class AccountDto {
	  private Long acNo;
	    private Long memberNo;
	    private Long cardNo;
	    private String accountNumber;
	    private String accountPw;   // 해시된 PW
	    private String status;      // "ACTIVE" / "CLOSED"
	    private Date createdAt;
	    private Date closedAt;

}

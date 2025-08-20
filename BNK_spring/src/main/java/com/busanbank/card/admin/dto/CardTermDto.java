package com.busanbank.card.admin.dto;

import lombok.Data;

@Data
public class CardTermDto {
	private Long cardNo;
	private Long pdfNo;
	private String isRequired; // 'Y' / 'N'
	private Integer displayOrder;

	// JOIN 조회용(화면 표시)
	private String pdfName;
	private String termScope; // common / specific / select
	private String isActive; // Y / N
	private String pdfCode;
}

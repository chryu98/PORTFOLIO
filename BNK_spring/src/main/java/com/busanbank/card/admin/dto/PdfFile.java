package com.busanbank.card.admin.dto;

import java.util.Date;

import lombok.Data;

@Data
public class PdfFile {

	private Long pdfNo;
	private String pdfName;
	private byte[] pdfData;
	private String isActive;
	private Date uploadDate;
	
	private Long adminNo;  // 업로드한 관리자 번호
	private String adminName;  // 조회용 필드 (DB에는 없음)

}

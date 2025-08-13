package com.busanbank.card.cardapply.dto;

import java.util.Date;

import lombok.Data;

@Data
public class PdfFilesDto {

	private Integer pdfNo;
	private String pdfName;
	private byte[] pdfData;
	private char isActive;
	private String termScope;
	private Date uploadDate;
	private int adminNo;
}

package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class PdfFilesDto {

	private Long pdfNo;
	private String pdfName;
	private byte[] pdfData;
	private String pdfDataBase64;
	private char isRequired;
}

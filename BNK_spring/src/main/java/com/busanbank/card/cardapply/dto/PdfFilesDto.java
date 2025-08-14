package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class PdfFilesDto {

	private Integer pdfNo;
	private String pdfName;
	private byte[] pdfData;
	private char isRequired;
}

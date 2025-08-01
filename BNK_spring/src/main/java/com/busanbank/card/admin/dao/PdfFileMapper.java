package com.busanbank.card.admin.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.admin.dto.PdfFile;

@Mapper
public interface PdfFileMapper {
	// 업로드
	void insertPdfFile(PdfFile pdfFile);

	// 수정
	void updatePdf(PdfFile dto);

	// 삭제
	int deletePdf(int pdfNo);

	// 조회
	List<PdfFile> selectAllPdfFiles();
}

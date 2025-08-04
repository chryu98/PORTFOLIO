package com.busanbank.card.admin.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.admin.dto.PdfFile;

@Mapper
public interface PdfFileMapper {
	// 업로드
	void insertPdfFile(PdfFile pdfFile);

	// 수정
	void updatePdfWithFile(PdfFile dto);
	void updatePdfWithoutFile(PdfFile dto);

	// 삭제
	int deletePdf(int pdfNo);

	// 조회
	List<PdfFile> selectAllPdfFiles();
	
	// 다운로드
	PdfFile selectPdfByNo(Long pdfNo);
	
	// 뷰어
	PdfFile findByPdfNo(@Param("pdfNo") int pdfNo);

}

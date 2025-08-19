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
    int deletePdf(@Param("pdfNo") int pdfNo);

    // 목록 (BLOB 제외)
    List<PdfFile> selectAllPdfFiles();

    // (선택) 서버 필터/페이징용 - 필요 시 Service에서 호출
    List<PdfFile> selectPdfFilesFiltered(@Param("scope") String scope,
                                         @Param("active") String active,
                                         @Param("offset") Integer offset,
                                         @Param("limit") Integer limit);

    // 단건 (다운로드/뷰어) - BLOB 포함
    PdfFile selectPdfByNo(@Param("pdfNo") Long pdfNo);
}

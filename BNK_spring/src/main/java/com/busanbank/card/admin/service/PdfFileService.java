package com.busanbank.card.admin.service;

import java.io.IOException;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.busanbank.card.admin.dao.PdfFileMapper;
import com.busanbank.card.admin.dto.PdfFile;

@Service
public class PdfFileService {

	 @Autowired
	    private PdfFileMapper pdfFileMapper;

	 // 업로드
	 public void uploadPdfFile(MultipartFile file, String pdfName, String isActive, Long adminNo) throws IOException {
		    
		 
		 PdfFile pdf = new PdfFile();
		    pdf.setPdfName(pdfName);
		    pdf.setPdfData(file.getBytes());
		    pdf.setIsActive(isActive);
		    pdf.setAdminNo(adminNo); // ✅ 관리자 번호 설정

		    pdfFileMapper.insertPdfFile(pdf);
		}

	 
	 // 수정
	 public void editPdfFile(Long pdfNo, String pdfName, String isActive, MultipartFile file, Long adminNo) throws IOException {
		    PdfFile dto = new PdfFile();
		    dto.setPdfNo(pdfNo);
		    dto.setPdfName(pdfName);
		    dto.setIsActive(isActive);
		    dto.setAdminNo(adminNo);

		    if (file != null && !file.isEmpty()) {
		        dto.setPdfData(file.getBytes()); // BLOB 파일
		        pdfFileMapper.updatePdfWithFile(dto);  // 파일 포함
		    } else {
		        pdfFileMapper.updatePdfWithoutFile(dto);  // 파일 제외
		    }
		}


	 
	 // 삭제
	 public boolean deletePdf(int pdfNo) {
		    return pdfFileMapper.deletePdf(pdfNo) > 0;
		}
	 
	 
	 // pdf 조회
	 public List<PdfFile> getAllPdfFiles() {
		    return pdfFileMapper.selectAllPdfFiles();  // Mapper 호출
		}
	 
	 // 다운로드
	 public PdfFile getPdfByNo(Long pdfNo) {
		    return pdfFileMapper.selectPdfByNo(pdfNo);
		}

	 // 뷰어
	 public PdfFile getPdfByNo(int pdfNo) {
	        return pdfFileMapper.findByPdfNo(pdfNo);
	    }

}

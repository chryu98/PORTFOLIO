package com.busanbank.card.admin.controller;

import java.io.IOException;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.dto.PdfFile;
import com.busanbank.card.admin.service.PdfFileService;
import com.busanbank.card.admin.session.AdminSession;

@RestController
@RequestMapping("/admin")
public class PdfFileController {

    @Autowired
    private PdfFileService pdfFileService;

    @Autowired
    private AdminSession adminSession;

    // 등록
    @PostMapping("/pdf/upload")
    public ResponseEntity<String> uploadPdf(
        @RequestParam("file") MultipartFile file,
        @RequestParam("pdfName") String pdfName,
        @RequestParam("isActive") String isActive
    ) {
        try {
            AdminDto loginUser = adminSession.getLoginUser();
            System.out.println("✔ loginUser: " + loginUser); // ✅ 1. null인지 확인
            if (loginUser == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
            }

            Long adminNo = loginUser.getAdminNo();
            pdfFileService.uploadPdfFile(file, pdfName, isActive, adminNo);
            System.out.println("✔ admin_no: " + loginUser.getAdminNo()); // ✅ 2. 값이 있는지 확인
            return ResponseEntity.ok("파일 업로드 성공");

        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("파일 업로드 실패: " + e.getMessage());
        }
    }
    
    // 수정
    @PutMapping("/pdf/update")
    public ResponseEntity<String> updatePdf(@RequestBody PdfFile dto) {
    	pdfFileService.updatePdf(dto); // pdfNo, pdfName, isActive 사용
        return ResponseEntity.ok("수정 완료");
    }

    // 삭제
    @DeleteMapping("/pdf/delete/{pdfNo}")
    public ResponseEntity<String> deletePdf(@PathVariable("pdfNo") int pdfNo) {
        System.out.println("🔥 DELETE 요청: pdfNo = " + pdfNo);
        boolean deleted = pdfFileService.deletePdf(pdfNo);

        if (deleted) {
            return ResponseEntity.ok("삭제 완료");
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("해당 PDF를 찾을 수 없습니다.");
        }
    }


    
    
    // 조회
    @GetMapping("/pdf/list")
    public ResponseEntity<List<PdfFile>> getAllPdfFiles() {
        List<PdfFile> list = pdfFileService.getAllPdfFiles();
        return ResponseEntity.ok(list);
    }
}

package com.busanbank.card.admin.controller;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.dto.PdfFile;
import com.busanbank.card.admin.service.PdfFileService;
import com.busanbank.card.admin.session.AdminSession;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/admin")
public class PdfFileController {

    @Autowired
    private PdfFileService pdfFileService;

    @Autowired
    private AdminSession adminSession;

    // 업로드
    @PostMapping("/pdf/upload")
    public ResponseEntity<String> uploadPdf(
        @RequestParam("file") MultipartFile file,
        @RequestParam("pdfName") String pdfName,
        @RequestParam("isActive") String isActive,
        @RequestParam("termScope") String termScope
    ) {
        try {
            AdminDto loginUser = adminSession.getLoginUser();
            if (loginUser == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
            }

            Long adminNo = loginUser.getAdminNo();
            pdfFileService.uploadPdfFile(file, pdfName, isActive, termScope, adminNo);
            return ResponseEntity.ok("파일 업로드 성공");

        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("파일 업로드 실패: " + e.getMessage());
        }
    }
    
    // 수정
    @PostMapping("/pdf/edit")
    public ResponseEntity<String> editPdf(
        @RequestParam("pdfNo") Long pdfNo,
        @RequestParam("pdfName") String pdfName,
        @RequestParam("isActive") String isActive,
        @RequestParam("termScope") String termScope,
        @RequestParam(value = "file", required = false) MultipartFile file
    ) {
        AdminDto loginUser = adminSession.getLoginUser();
        if (loginUser == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        try {
            pdfFileService.editPdfFile(pdfNo, pdfName, isActive, termScope, file, loginUser.getAdminNo());
            return ResponseEntity.ok("수정 완료");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("수정 실패: " + e.getMessage());
        }
    }



    // 삭제
    @PostMapping("/pdf/delete")
    public ResponseEntity<String> deletePdfViaPost(@RequestParam("pdfNo") int pdfNo) {
        System.out.println("🔥 POST로 삭제 요청: pdfNo = " + pdfNo);
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
    
    // 다운로드
    @GetMapping("/pdf/download/{pdfNo}")
    public ResponseEntity<byte[]> downloadPdf(@PathVariable("pdfNo") Long pdfNo) {
        PdfFile pdf = pdfFileService.getPdfByNo(pdfNo);
        if (pdf == null || pdf.getPdfData() == null) {
            return ResponseEntity.notFound().build();
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF); //브라우저가 pdf 인식
        headers.setContentDisposition(ContentDisposition
            .builder("attachment") //다운로드로 처리
            .filename(pdf.getPdfName() + ".pdf", StandardCharsets.UTF_8)
            .build());

        return new ResponseEntity<>(pdf.getPdfData(), headers, HttpStatus.OK);
    }
    
    // 뷰어
    @GetMapping("/pdf/view/{pdfNo}")
    public ResponseEntity<byte[]> viewPdf(@PathVariable("pdfNo") int pdfNo) {
        PdfFile file = pdfFileService.getPdfByNo(pdfNo);
        if (file == null) {
            return ResponseEntity.notFound().build();
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDisposition(ContentDisposition.inline()
            .filename(file.getPdfName() + ".pdf", StandardCharsets.UTF_8)
            .build());

        return new ResponseEntity<>(file.getPdfData(), headers, HttpStatus.OK);
    }


}

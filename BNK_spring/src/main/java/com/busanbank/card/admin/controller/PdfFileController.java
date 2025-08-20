package com.busanbank.card.admin.controller;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

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

@RestController
@RequestMapping("/admin")

public class PdfFileController {

    private static final Set<String> ALLOWED_SCOPES = Set.of("common","specific","select");
    private static final Set<String> ALLOWED_ACTIVE = Set.of("Y","N");

    @Autowired
    private PdfFileService pdfFileService;

    @Autowired
    private AdminSession adminSession;

    // ========== 업로드 ==========
    @PostMapping("/pdf/upload")
    public ResponseEntity<String> uploadPdf(
            @RequestParam("file") MultipartFile file,
            @RequestParam("pdfName") String pdfName,
            @RequestParam("isActive") String isActive,
            @RequestParam("termScope") String termScope
    ) {
        AdminDto loginUser = adminSession.getLoginUser();
        if (loginUser == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인이 필요합니다.");
        }

        // 기본 검증
        if (!ALLOWED_ACTIVE.contains(isActive)) {
            return ResponseEntity.badRequest().body("isActive 값은 Y/N 만 허용됩니다.");
        }
        if (!ALLOWED_SCOPES.contains(termScope)) {
            return ResponseEntity.badRequest().body("termScope 값은 common/specific/select 만 허용됩니다.");
        }
        if (file == null || file.isEmpty()) {
            return ResponseEntity.badRequest().body("PDF 파일이 필요합니다.");
        }
        if (!"application/pdf".equalsIgnoreCase(file.getContentType())) {
            // 일부 브라우저는 octet-stream으로 올 때도 있어 contentType만으로 단정하기 어렵지만, 기본 체크 예시
            // 필요시 확장자/시그니처 검사 추가 가능
        }

        try {
            pdfFileService.uploadPdfFile(file, pdfName, isActive, termScope, loginUser.getAdminNo());
            return ResponseEntity.ok("파일 업로드 성공");
        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("파일 업로드 실패: " + e.getMessage());
        }
    }

    // ========== 수정 ==========
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

        if (!ALLOWED_ACTIVE.contains(isActive)) {
            return ResponseEntity.badRequest().body("isActive 값은 Y/N 만 허용됩니다.");
        }
        if (!ALLOWED_SCOPES.contains(termScope)) {
            return ResponseEntity.badRequest().body("termScope 값은 common/specific/select 만 허용됩니다.");
        }

        try {
            pdfFileService.editPdfFile(pdfNo, pdfName, isActive, termScope, file, loginUser.getAdminNo());
            return ResponseEntity.ok("수정 완료");
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("수정 실패: " + e.getMessage());
        }
    }

    // ========== 삭제 ==========
    @PostMapping("/pdf/delete")
    public ResponseEntity<String> deletePdfViaPost(@RequestParam("pdfNo") int pdfNo) {
        boolean deleted = pdfFileService.deletePdf(pdfNo);
        if (deleted) return ResponseEntity.ok("삭제 완료");
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("해당 PDF를 찾을 수 없습니다.");
    }

    // ========== 리스트 (프론트 호환: 그대로 /admin/pdf/list 호출하면 전체 반환) ==========
    // 추가로 scope, active, page, size 쿼리 파라미터를 지원 (선택)
    @GetMapping("/pdf/list")
    public ResponseEntity<List<PdfFile>> getAllPdfFiles(
            @RequestParam(value = "scope", required = false) String scope,   // common|specific|select
            @RequestParam(value = "active", required = false) String active, // Y|N
            @RequestParam(value = "page", required = false, defaultValue = "0") int page,
            @RequestParam(value = "size", required = false, defaultValue = "0") int size
    ) {
        // 기본: 전체 리스트(Blob 제외) 반환
        // PdfFileService.selectAllPdfFilesMeta() 같은 메서드를 만들어 pdf_data를 쿼리에서 제외하는 걸 권장
        List<PdfFile> list = pdfFileService.getAllPdfFiles(); // 기존 메서드 재사용 가능

        // 간단 필터 (서버에서 필터링; 대량 데이터면 Mapper에 조건부 쿼리/페이징 권장)
        if (scope != null && ALLOWED_SCOPES.contains(scope)) {
            list.removeIf(p -> p.getTermScope() == null || !p.getTermScope().equals(scope));
        }
        if (active != null && ALLOWED_ACTIVE.contains(active)) {
            list.removeIf(p -> p.getIsActive() == null || !p.getIsActive().equals(active));
        }

        // 간단 페이징 (메모리 슬라이싱; 대량이면 DB 페이징 권장)
        if (size > 0) {
            int from = Math.max(page, 0) * size;
            int to = Math.min(from + size, list.size());
            if (from < to) list = list.subList(from, to);
            else list = List.of();
        }

        return ResponseEntity.ok(list);
    }

    // ========== 다운로드 ==========
    @GetMapping("/pdf/download/{pdfNo}")
    public ResponseEntity<byte[]> downloadPdf(@PathVariable("pdfNo") Long pdfNo) {
        PdfFile pdf = pdfFileService.getPdfByNo(pdfNo);
        if (pdf == null || pdf.getPdfData() == null) {
            return ResponseEntity.notFound().build();
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDisposition(ContentDisposition
                .attachment()
                .filename(safeFilename(pdf.getPdfName()) + ".pdf", StandardCharsets.UTF_8)
                .build());

        return new ResponseEntity<>(pdf.getPdfData(), headers, HttpStatus.OK);
    }

    // ========== 뷰어 ==========
    @GetMapping("/pdf/view/{pdfNo}")
    public ResponseEntity<byte[]> viewPdf(@PathVariable("pdfNo") Long pdfNo) { // Long으로 통일
        PdfFile file = pdfFileService.getPdfByNo(pdfNo);
        if (file == null || file.getPdfData() == null) {
            return ResponseEntity.notFound().build();
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDisposition(ContentDisposition
                .inline()
                .filename(safeFilename(file.getPdfName()) + ".pdf", StandardCharsets.UTF_8)
                .build());

        return new ResponseEntity<>(file.getPdfData(), headers, HttpStatus.OK);
    }

    // 파일명 안전화(개행/따옴표 등 제거)
    private String safeFilename(String s) {
        if (s == null) return "document";
        String cleaned = s.replaceAll("[\\r\\n\"\\\\/<>|:*?]", "_").trim();
        if (cleaned.isEmpty()) cleaned = "document";
        return cleaned;
    }
}

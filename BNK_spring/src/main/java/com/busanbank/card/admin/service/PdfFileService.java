package com.busanbank.card.admin.service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.busanbank.card.admin.dao.PdfFileMapper;
import com.busanbank.card.admin.dto.PdfFile;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class PdfFileService {

    private final PdfFileMapper pdfFileMapper;

    private static final Set<String> ALLOWED_SCOPES = Set.of("common","specific","select");
    private static final Set<String> ALLOWED_ACTIVE = Set.of("Y","N");

    /* ==========================
     * 업로드
     * ========================== */
    public void uploadPdfFile(MultipartFile file,
                              String pdfName,
                              String isActive,
                              String termScope,
                              Long adminNo) throws IOException {

        validateActive(isActive);
        validateScope(termScope);
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("PDF 파일이 필요합니다.");
        }

        PdfFile pdf = new PdfFile();
        pdf.setPdfName(safeName(pdfName));
        pdf.setPdfData(file.getBytes());
        pdf.setIsActive(isActive);
        pdf.setTermScope(termScope);
        pdf.setAdminNo(adminNo);

        pdfFileMapper.insertPdfFile(pdf);
    }

    /* ==========================
     * 수정 (파일 교체 옵션)
     * ========================== */
    public void editPdfFile(Long pdfNo,
                            String pdfName,
                            String isActive,
                            String termScope,
                            MultipartFile file,
                            Long adminNo) throws IOException {

        if (pdfNo == null) throw new IllegalArgumentException("pdfNo는 필수입니다.");
        validateActive(isActive);
        validateScope(termScope);

        PdfFile dto = new PdfFile();
        dto.setPdfNo(pdfNo);
        dto.setPdfName(safeName(pdfName));
        dto.setIsActive(isActive);
        dto.setTermScope(termScope);
        dto.setAdminNo(adminNo);

        if (file != null && !file.isEmpty()) {
            dto.setPdfData(file.getBytes());
            pdfFileMapper.updatePdfWithFile(dto);
        } else {
            pdfFileMapper.updatePdfWithoutFile(dto);
        }
    }

    /* ==========================
     * 삭제
     * ========================== */
    public boolean deletePdf(int pdfNo) {
        return pdfFileMapper.deletePdf(pdfNo) > 0;
    }

    /* ==========================
     * 목록 조회 (그대로 전체 반환)
     *  - Mapper의 selectAllPdfFiles() 사용
     *  - 응답은 업로드일 최신순으로 정렬
     * ========================== */
    public List<PdfFile> getAllPdfFiles() {
        List<PdfFile> list = pdfFileMapper.selectAllPdfFiles();
        if (list == null) return List.of();

        // 업로드일 내림차순 정렬 (null 안전)
        return list.stream()
                   .sorted(Comparator.comparing(PdfFile::getUploadDate,
                               Comparator.nullsLast(Comparator.naturalOrder()))
                               .reversed())
                   .collect(Collectors.toList());
    }

    /* ==========================
     * (선택) 서버단 필터/페이징 헬퍼
     *  - 컨트롤러에서 scope/active/page/size 파라미터를
     *    받을 때 사용할 수 있음
     *  - 대용량이면 Mapper에 조건부 쿼리/페이징을 권장
     * ========================== */
    public List<PdfFile> getPdfFiles(String scope, String active, Integer page, Integer size) {
        List<PdfFile> base = new ArrayList<>(getAllPdfFiles());

        if (scope != null && ALLOWED_SCOPES.contains(scope)) {
            base.removeIf(p -> p.getTermScope() == null || !scope.equals(p.getTermScope()));
        }
        if (active != null && ALLOWED_ACTIVE.contains(active)) {
            base.removeIf(p -> p.getIsActive() == null || !active.equals(p.getIsActive()));
        }

        if (size != null && size > 0) {
            int p = Math.max(page == null ? 0 : page, 0);
            int from = p * size;
            int to = Math.min(from + size, base.size());
            if (from >= base.size()) return List.of();
            return base.subList(from, to);
        }
        return base;
    }

    /* ==========================
     * 단건 조회 (다운로드/뷰 공용)
     *  - Long으로 통일
     * ========================== */
    public PdfFile getPdfByNo(Long pdfNo) {
        if (pdfNo == null) return null;
        return pdfFileMapper.selectPdfByNo(pdfNo);
    }

    /* ==========================
     * 유틸
     * ========================== */
    private void validateScope(String termScope) {
        if (!ALLOWED_SCOPES.contains(termScope)) {
            throw new IllegalArgumentException("termScope 값은 common/specific/select 만 허용됩니다.");
        }
    }

    private void validateActive(String isActive) {
        if (!ALLOWED_ACTIVE.contains(isActive)) {
            throw new IllegalArgumentException("isActive 값은 Y/N 만 허용됩니다.");
        }
    }

    /** 파일명 안전화 (헤더/파일 시스템 이슈 예방) */
    private String safeName(String name) {
        if (name == null) return "document";
        String cleaned = name.replaceAll("[\\r\\n\"\\\\/<>|:*?]", "_").trim();
        if (cleaned.isEmpty()) cleaned = "document";
        // HTTP 헤더 호환을 고려해 UTF-8로만 안전하게 (필요시 추가 변환)
        return new String(cleaned.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
    }
}

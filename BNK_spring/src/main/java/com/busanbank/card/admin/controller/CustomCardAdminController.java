package com.busanbank.card.admin.controller;

import com.busanbank.card.admin.service.CustomCardAdminService;
import com.busanbank.card.custom.dto.CustomCardDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin/api/custom-cards")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CustomCardAdminController {

    private final CustomCardAdminService service;

    /** 목록 조회 (페이징) */
    @GetMapping
    public Map<String, Object> list(
            @RequestParam(name = "aiResult", required = false) String aiResult,
            @RequestParam(name = "memberNo", required = false) Long memberNo,
            @RequestParam(name = "status",   required = false) String status,
            @RequestParam(name = "page",     defaultValue = "0") int page,
            @RequestParam(name = "size",     defaultValue = "20") int size
    ) {
        int total = service.count(aiResult, memberNo, status);
        List<CustomCardDto> items = service.list(aiResult, memberNo, status, page, size);
        return Map.of("total", total, "items", items, "page", page, "size", size);
    }

    /** 상세 */
    @GetMapping("/{customNo}")
    public CustomCardDto detail(@PathVariable("customNo") Long customNo) {
        return service.detail(customNo);
    }

    /** 상태/사유 업데이트 */
    @PostMapping("/{customNo}/status")
    public Map<String, Object> updateStatus(@PathVariable("customNo") Long customNo,
                                            @RequestParam(name = "status") String status,
                                            @RequestParam(name = "reason", required = false) String reason) {
        int n = service.updateStatus(customNo, status, reason);
        return Map.of("updated", n);
    }

    /** 이미지 바이너리 (PNG/JPEG 자동 판별) */
    @GetMapping("/{customNo}/image")
    public ResponseEntity<byte[]> image(@PathVariable("customNo") long customNo) {
        CustomCardDto dto = service.detail(customNo);
        if (dto == null || dto.getImageBlob() == null) {
            return ResponseEntity.notFound().build();
        }

        byte[] img = dto.getImageBlob();

        // PNG 시그니처(89 50 4E 47)로 간단 판별
        boolean isPng = img.length >= 4
                && (img[0] & 0xFF) == 0x89
                && (img[1] & 0xFF) == 0x50
                && (img[2] & 0xFF) == 0x4E
                && (img[3] & 0xFF) == 0x47;

        MediaType ct = isPng ? MediaType.IMAGE_PNG : MediaType.IMAGE_JPEG;
        return ResponseEntity.ok().contentType(ct).body(img);
    }
}

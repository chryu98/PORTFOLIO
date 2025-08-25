package com.busanbank.card.custom.controller;


import java.io.IOException;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.busanbank.card.custom.dto.CustomCardDto;
import com.busanbank.card.custom.mapper.CustomCardMapper;
import com.busanbank.card.custom.service.CustomCardService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/custom-cards")
@RequiredArgsConstructor
public class CustomCardController {
  private final CustomCardService service;

  
  private final CustomCardMapper mapper;
  
  
  @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public ResponseEntity<?> create(
      @RequestParam("memberNo") Long memberNo,
      @RequestParam(value = "customService", required = false) String customService,
      @RequestPart("image") MultipartFile image
  ) throws IOException {
    if (image.isEmpty()) {
      return ResponseEntity.badRequest().body("image is required");
    }
    byte[] png = image.getBytes();
    Long id = service.save(memberNo, png, customService);
    return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("customNo", id));
  }
  
  /** 상세 조회: GET /api/custom-cards/{customNo} */
  @GetMapping("/{customNo}")
  public ResponseEntity<?> detail(@PathVariable("customNo") Long customNo) {
    var dto = mapper.findById(customNo);
    if (dto == null) return ResponseEntity.notFound().build();
    dto.setImageBlob(null);
    return ResponseEntity.ok(dto);
  }
  
  
  @PostMapping("/{customNo}/ai")
  public ResponseEntity<?> updateAi(
          @PathVariable("customNo") Long customNo,
          @RequestBody AiUpdateRequest req
  ) {
      int n = service.updateAi(customNo, req.getAiResult(), req.getAiReason());
      return ResponseEntity.ok(Map.of("updated", n));
  }

  // 👇 같은 파일 하단에 DTO 하나 추가(레코드/롬복 둘 다 OK)
  static class AiUpdateRequest {
      private String aiResult; // "ACCEPT" | "REJECT"
      private String aiReason; // 사람친화 사유 문자열
      public String getAiResult() { return aiResult; }
      public String getAiReason() { return aiReason; }
  }
  
  
  
}
	
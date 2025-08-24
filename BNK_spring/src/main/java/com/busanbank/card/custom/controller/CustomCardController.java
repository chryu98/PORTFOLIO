package com.busanbank.card.custom.controller;


import java.io.IOException;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
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
}
	
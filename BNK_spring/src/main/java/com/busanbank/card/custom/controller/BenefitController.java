package com.busanbank.card.custom.controller;

import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import com.busanbank.card.custom.dao.BenefitMapper;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/custom-cards")
@RequiredArgsConstructor
public class BenefitController {

  private final BenefitMapper benefitMapper;

  /** 혜택 조회 (custom_service 만 단건 조회) */
  @GetMapping(value = "/{customNo}/benefit", produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<?> getBenefit(@PathVariable("customNo") Long customNo) {
    String benefit = benefitMapper.getBenefit(customNo);
    if (benefit == null && benefitMapper.exists(customNo) == 0) {
      return ResponseEntity.notFound().build();
    }
    return ResponseEntity.ok(Map.of(
        "customNo", customNo,
        "customService", benefit
    ));
  }

  /** 혜택 수정/교체 */
  @PutMapping(value = "/{customNo}/benefit", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
  @Transactional
  public ResponseEntity<?> updateBenefit(
      @PathVariable("customNo") Long customNo,
      @RequestBody Map<String, String> body
  ) {
    String customService = body.get("customService");
    if (customService == null) customService = "";
    int rows = benefitMapper.updateBenefit(customNo, customService);
    if (rows == 0) return ResponseEntity.notFound().build();
    benefitMapper.touch(customNo);
    return ResponseEntity.ok(Map.of("updated", true));
  }

  /** 혜택 제거(빈 값으로 초기화) */
  @DeleteMapping(value = "/{customNo}/benefit", produces = MediaType.APPLICATION_JSON_VALUE)
  @Transactional
  public ResponseEntity<?> clearBenefit(@PathVariable("customNo") Long customNo) {
    int rows = benefitMapper.updateBenefit(customNo, "");
    if (rows == 0) return ResponseEntity.notFound().build();
    benefitMapper.touch(customNo);
    return ResponseEntity.ok(Map.of("cleared", true));
  }
}

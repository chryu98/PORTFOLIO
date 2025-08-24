// com/busanbank/card/cardapply/controller/ApplicationPromotionController.java
package com.busanbank.card.cardapply.controller;

import java.util.Map;
import java.util.Optional;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.cardapply.dao.ApplicationMapper;
import com.busanbank.card.cardapply.dao.ApplicationPersonMapper;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/card/apply")
public class ApplicationPromotionController {

  private final ApplicationMapper appMapper;
  private final ApplicationPersonMapper personMapper;

  private static int nz(Integer v) { return v != null ? v : 0; }  // ✅ null → 0

  @PostMapping("/promote/{appNo}")
  @Transactional
  public ResponseEntity<?> promote(@PathVariable("appNo") long appNo) {

    // 0) 잠금 시도 (mapper가 null을 돌려줘도 안전)
    int appLocked = 0;
    int personLocked = 0;
    try { appLocked    = nz(appMapper.lockTemp(appNo));    } catch (Exception ignore) {}
    try { personLocked = nz(personMapper.lockTemp(appNo)); } catch (Exception ignore) {}

    // existsFinal도 null 가능성이 있으면 정규화
    int finalExists = 0;
    try { finalExists = nz(appMapper.existsFinal(appNo)); } catch (Exception ignore) {}

    // 1) 최소 보장: FINAL조차 없고 TEMP도 없으면 404
    if (appLocked == 0 && finalExists == 0) {
      return ResponseEntity.status(404)
          .body(Map.of("status", "application_temp_not_found"));
    }

    // 2) MERGE: CARD_APPLICATION (TEMP 있으면 병합/없으면 스킵)
    if (appLocked > 0) {
      appMapper.mergeFromTemp(appNo);
      // 삭제는 맨 마지막에!
    }

    // 3) MERGE: APPLICATION_PERSON (TEMP 있으면 병합/없으면 스킵)
    if (personLocked > 0) {
      personMapper.mergeFromTemp(appNo);
      // 자식 TEMP 먼저 삭제
      personMapper.deleteTemp(appNo);
    }

    // 4) 마지막에 부모 TEMP 삭제 (자식 삭제가 끝난 이후)
    if (appLocked > 0) {
      appMapper.deleteTemp(appNo);
    }

    return ResponseEntity.ok(Map.of("status", "promoted"));
  }
}

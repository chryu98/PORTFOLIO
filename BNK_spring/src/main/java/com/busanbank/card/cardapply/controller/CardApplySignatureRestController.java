package com.busanbank.card.cardapply.controller;

import com.busanbank.card.cardapply.dao.CardApplySignatureDao;
import com.busanbank.card.cardapply.dto.CardApplySignatureRec;
import com.busanbank.card.cardapply.dto.SignatureInfoRes;
import com.busanbank.card.cardapply.dto.SignatureSaveReq;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.Map;

@RestController
@RequestMapping("/api/card/apply/sign")
@RequiredArgsConstructor
public class CardApplySignatureRestController {

  private final CardApplySignatureDao dao;

  private Long currentMemberNo() {
    var auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated()) return null;

    Object principal = auth.getPrincipal();
    try {
      var m = principal.getClass().getMethod("getMemberNo");
      Object v = m.invoke(principal);
      if (v instanceof Number n) return n.longValue();
      if (v instanceof String s && s.matches("\\d+")) return Long.parseLong(s);
    } catch (NoSuchMethodException ignore) { } catch (Exception ignore) { }

    String name = auth.getName();
    if (name != null && name.matches("\\d+")) return Long.parseLong(name);

    Object details = auth.getDetails();
    if (details instanceof Map<?,?> m) {
      Object v = m.get("memberNo");
      if (v instanceof Number n) return n.longValue();
      if (v instanceof String s && s.matches("\\d+")) return Long.parseLong(s);
    }
    return null;
  }

  private static byte[] decodeBase64Image(String data) {
    if (data == null) return null;
    int comma = data.indexOf(',');
    String b64 = (comma >= 0) ? data.substring(comma + 1) : data;
    return Base64.getDecoder().decode(b64);
  }

  /** 저장/덮어쓰기: FINAL 없으면 컨트롤러에서 바로 승격 후 진행 */
  @PostMapping
  public ResponseEntity<?> save(@RequestBody SignatureSaveReq req) {
    Long memberNo = currentMemberNo();
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    System.out.println("[SIGN] appNo=" + req.getApplicationNo()
        + " loginName=" + (auth != null ? auth.getName() : null)
        + " memberNo=" + memberNo);

    if (memberNo == null) {
      return ResponseEntity.status(401).body(Map.of("ok", false, "message", "로그인이 필요합니다."));
    }
    if (req.getApplicationNo() == null || req.getImageBase64() == null) {
      return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "입력 누락"));
    }

    Long appNo = req.getApplicationNo();

    // 1) FINAL 보장: 없고 TEMP에 있으면 즉시 승격 (컨트롤러에서 처리)
    if (dao.existsInFinal(appNo) == 0) {
      if (dao.existsInTemp(appNo) == 0) {
        return ResponseEntity.status(404).body(Map.of("ok", false, "message", "신청서를 찾을 수 없습니다."));
      }
      // 승격: INSERT -> TEMP 삭제 -> FINAL touch (멱등)
      dao.promoteInsertFinal(appNo);
      dao.deleteTemp(appNo);
      dao.touchFinal(appNo);
    }

    // 2) 오너 검사 (FINAL)
    if (dao.isOwnerInFinal(appNo, memberNo) == 0) {
      return ResponseEntity.status(403).body(Map.of("ok", false, "message", "신청 소유자가 아닙니다."));
    }

    // 3) 저장
    byte[] bytes = decodeBase64Image(req.getImageBase64());
    dao.upsertSignatureFinal(appNo, memberNo, bytes);

    return ResponseEntity.ok(Map.of("ok", true, "message", "서명이 저장되었습니다."));
  }

  /** 존재 여부 (FINAL만) */
  @GetMapping("/{appNo}/exists")
  public ResponseEntity<Map<String, Object>> exists(@PathVariable Long appNo) {
    boolean exists = dao.findFinalByApplicationNo(appNo) != null;
    return ResponseEntity.ok(Map.of("exists", exists));
  }

  /** 메타 정보 (FINAL만) */
  @GetMapping("/{appNo}")
  public ResponseEntity<SignatureInfoRes> info(@PathVariable Long appNo) {
    CardApplySignatureRec r = dao.findFinalByApplicationNo(appNo);
    SignatureInfoRes res = new SignatureInfoRes();
    res.setApplicationNo(appNo);
    if (r != null) {
      res.setExists(true);
      res.setSignNo(r.getSignNo());
      res.setMemberNo(r.getMemberNo());
      if (r.getSignedAt() != null) {
        res.setSignedAt(r.getSignedAt().toInstant()
            .atZone(ZoneId.systemDefault())
            .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME));
      }
    } else {
      res.setExists(false);
    }
    return ResponseEntity.ok(res);
  }
}

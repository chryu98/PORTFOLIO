// src/main/java/com/busanbank/card/cardapply/controller/CardApplySignatureRestController.java
package com.busanbank.card.cardapply.controller;

import com.busanbank.card.cardapply.dao.ApplicationMapper;
import com.busanbank.card.cardapply.dao.CardApplySignatureDao;
import com.busanbank.card.cardapply.dto.CardApplySignatureRec;
import com.busanbank.card.cardapply.dto.SignatureInfoRes;
import com.busanbank.card.cardapply.dto.SignatureSaveReq;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
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
    private final ApplicationMapper appMapper; // 상태 업데이트용

    // 로그인 사용자 memberNo 추출
    private Long currentMemberNo() {
        var ctx = SecurityContextHolder.getContext();
        Authentication auth = (ctx != null) ? ctx.getAuthentication() : null;
        if (auth == null || !auth.isAuthenticated()) return null;

        Object principal = auth.getPrincipal();
        try {
            var m = principal.getClass().getMethod("getMemberNo");
            Object v = m.invoke(principal);
            if (v instanceof Number n) return n.longValue();
            if (v instanceof String s && s.matches("\\d+")) return Long.parseLong(s);
        } catch (NoSuchMethodException ignore) {
        } catch (Exception ignore) {
        }

        String name = auth.getName();
        if (name != null && name.matches("\\d+")) return Long.parseLong(name);

        Object details = auth.getDetails();
        if (details instanceof Map<?, ?> m) {
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

    /** ✅ 서명 대상 상태 조회 (FINAL)
     * GET /api/card/apply/sign/info?applicationNo=123
     */
    @GetMapping("/info")
    public ResponseEntity<?> infoByQuery(@RequestParam("applicationNo") Long appNo) {
        String status = appMapper.getFinalStatus(appNo);
        if (status == null) {
            return ResponseEntity.status(404).body(Map.of("status", "not_found"));
        }
        return ResponseEntity.ok(Map.of("applicationNo", appNo, "status", status));
    }

    /** ✅ 서명 세션 생성 (예: 외부 페이지로 리다이렉트)
     * POST /api/card/apply/sign/session/{appNo}
     * 상태를 SIGNING 으로 전환
     */
    @PostMapping("/session/{appNo}")
    @Transactional
    public ResponseEntity<?> createSession(@PathVariable("appNo") Long appNo) {
        appMapper.updateStatus(appNo, "SIGNING");
        // 실제 연동 시 외부 URL/토큰을 내려주면 됨
        return ResponseEntity.ok(Map.of(
                "type", "redirect",
                "url", "https://example.com/sign/callback?appNo=" + appNo
        ));
    }

    /** ✅ 서명 결과 조회
     * GET /api/card/apply/sign/result/{appNo}
     * (데모용) 현재 FINAL 상태 그대로 돌려줌
     */
    @GetMapping("/result/{appNo}")
    public ResponseEntity<?> result(@PathVariable("appNo") Long appNo) {
        String status = appMapper.getFinalStatus(appNo);
        if (status == null) {
            return ResponseEntity.status(404).body(Map.of("status", "not_found"));
        }
        return ResponseEntity.ok(Map.of("status", status));
    }

    /** ✅ 사인 이미지 업로드(패드 플로우)
     * POST /api/card/apply/sign
     * body: { applicationNo, imageBase64: "data:image/png;base64,..." }
     *
     * 동작:
     *  1) FINAL 미존재면 TEMP → FINAL 승격 보장
     *  2) 오너십 검사
     *  3) BLOB 저장(upsert)
     *  4) 같은 트랜잭션에서 CARD_APPLICATION.STATUS='SIGNED' 로 전환
     */
    @PostMapping
    @Transactional
    public ResponseEntity<?> save(@RequestBody SignatureSaveReq req) {
        Long memberNo = currentMemberNo();
        if (memberNo == null) {
            return ResponseEntity.status(401).body(Map.of("ok", false, "message", "로그인이 필요합니다."));
        }
        if (req.getApplicationNo() == null || req.getImageBase64() == null) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "입력 누락"));
        }

        Long appNo = req.getApplicationNo();

        // 1) FINAL 보장 (없으면 TEMP → FINAL)
        if (dao.existsInFinal(appNo) == 0) {
            if (dao.existsInTemp(appNo) == 0) {
                return ResponseEntity.status(404).body(Map.of("ok", false, "message", "신청서를 찾을 수 없습니다."));
            }
            dao.promoteInsertFinal(appNo);
            try { dao.deleteTemp(appNo); } catch (Exception ignore) {}
            dao.touchFinal(appNo);
        }

        // 2) 오너 검사
        if (dao.isOwnerInFinal(appNo, memberNo) == 0) {
            return ResponseEntity.status(403).body(Map.of("ok", false, "message", "신청 소유자가 아닙니다."));
        }

        // 3) BLOB 저장
        byte[] bytes = decodeBase64Image(req.getImageBase64());
        if (bytes == null || bytes.length == 0) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "유효하지 않은 이미지"));
        }
        dao.upsertSignatureFinal(appNo, memberNo, bytes);

        // 4) 상태 전환: SIGNED
        appMapper.updateStatus(appNo, "SIGNED");

        return ResponseEntity.ok(Map.of("ok", true, "status", "SIGNED", "message", "서명이 저장되었습니다."));
    }

    /** ✅ 존재 여부 (FINAL만)
     * GET /api/card/apply/sign/{appNo}/exists  -> { exists: true|false }
     */
    @GetMapping("/{appNo}/exists")
    public ResponseEntity<Map<String, Object>> exists(@PathVariable("appNo") Long appNo) {
        boolean exists = dao.findFinalByApplicationNo(appNo) != null;
        return ResponseEntity.ok(Map.of("exists", exists));
    }

    /** ✅ 메타 정보 (FINAL만)
     * GET /api/card/apply/sign/{appNo}
     */
    @GetMapping("/{appNo}")
    public ResponseEntity<SignatureInfoRes> info(@PathVariable("appNo") Long appNo) {
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

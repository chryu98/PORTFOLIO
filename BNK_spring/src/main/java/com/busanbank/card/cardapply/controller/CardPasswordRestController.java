package com.busanbank.card.cardapply.controller;

import com.busanbank.card.cardapply.dao.CardPasswordMapper;
import com.busanbank.card.cardapply.dto.CardPaswwordDto;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/card/apply/api/card-password")
public class CardPasswordRestController {

    private final CardPasswordMapper mapper;
    private final PasswordEncoder passwordEncoder;

    public CardPasswordRestController(CardPasswordMapper mapper,
                                      PasswordEncoder passwordEncoder) {
        this.mapper = mapper;
        this.passwordEncoder = passwordEncoder;
    }

    // 요청 DTO (저장 전용)
    public static class SetPinReq { public String pin1; public String pin2; }

    private Long sessionMemberNo(HttpSession session) {
        Object s = session.getAttribute("loginMemberNo");
        if (s instanceof Integer i) return i.longValue();
        if (s instanceof Long l) return l;
        return null;
    }

    /** PIN 저장(덮어쓰기): (memberNo, cardNo) 기존행 삭제 후 1행만 저장 */
 // ✅ URL에 {cardNo} 포함
    @PostMapping("/{cardNo}/pin")
    @Transactional
    public ResponseEntity<?> setPin(@PathVariable("cardNo") long cardNo,
                                    @RequestBody SetPinReq req,
                                    HttpSession session) {
        Long memberNo = sessionMemberNo(session);
        if (memberNo == null)
            return ResponseEntity.status(401).body(Map.of("ok", false, "message", "로그인이 필요합니다."));

        if (req == null || req.pin1 == null || req.pin2 == null)
            return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "입력 누락"));

        if (!req.pin1.equals(req.pin2) || !req.pin1.matches("^\\d{4,6}$"))
            return ResponseEntity.ok(Map.of("ok", false, "message", "PIN은 숫자 4~6자리, 두 번 동일히 입력"));

        mapper.deleteByMemberCard(memberNo, cardNo);

        String bcrypt = passwordEncoder.encode(req.pin1);
        CardPaswwordDto rec = new CardPaswwordDto();
        rec.setMemberNo(memberNo);
        rec.setCardNo(cardNo);
        rec.setPinPhc(bcrypt);
        mapper.insert(rec);

        return ResponseEntity.ok(Map.of("ok", true, "message", "PIN이 저장되었습니다."));
    }

}

package com.busanbank.card.cardapply.controller;

import com.busanbank.card.cardapply.dao.CardPasswordMapper;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.CardPaswwordDto;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/card/apply/api/card-password")
public class CardPasswordRestController {

    private final CardPasswordMapper mapper;
    private final ICardApplyDao cardApplyDao;   // ✅ 상태 갱신용 DAO 추가
    private final PasswordEncoder passwordEncoder;

    public CardPasswordRestController(CardPasswordMapper mapper,
                                      ICardApplyDao cardApplyDao,
                                      PasswordEncoder passwordEncoder) {
        this.mapper = mapper;
        this.cardApplyDao = cardApplyDao;
        this.passwordEncoder = passwordEncoder;
    }

    public static class SetPinReq { 
        public String pin1; 
        public String pin2; 
        public Integer applicationNo;  // ✅ 상태 갱신용 (임시신청 PK)
    }

    private Long sessionMemberNo(HttpSession session) {
        if (session == null) return null;
        Object s = session.getAttribute("loginMemberNo");
        if (s instanceof Integer i) return i.longValue();
        if (s instanceof Long l) return l;
        return null;
    }

    private Long resolveMemberNoFromAuth() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) return null;
        Object principal = auth.getPrincipal();
        try {
            var m = principal.getClass().getMethod("getMemberNo");
            Object val = m.invoke(principal);
            if (val instanceof Number n) return n.longValue();
            if (val instanceof String s && s.matches("\\d+")) return Long.parseLong(s);
        } catch (Exception ignore) {}
        String name = auth.getName();
        if (name != null && name.matches("\\d+")) return Long.parseLong(name);
        return null;
    }

    /** PIN 저장 후 카드 신청 상태(PIN_SET) 갱신 */
    @PostMapping("/{cardNo}/pin")
    @Transactional
    public ResponseEntity<?> setPin(@PathVariable("cardNo") long cardNo,
                                    @RequestBody SetPinReq req,
                                    HttpSession session) {
        Long memberNo = resolveMemberNoFromAuth();
        if (memberNo == null) memberNo = sessionMemberNo(session);

        if (memberNo == null) {
            return ResponseEntity.status(401).body(Map.of("ok", false, "message", "로그인이 필요합니다."));
        }
        if (req == null || req.pin1 == null || req.pin2 == null) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "입력 누락"));
        }
        if (!req.pin1.equals(req.pin2) || !req.pin1.matches("^\\d{4,6}$")) {
            return ResponseEntity.ok(Map.of("ok", false, "message", "PIN은 숫자 4~6자리, 두 번 동일히 입력"));
        }

        // 1) PIN 저장
        mapper.deleteByMemberCard(memberNo, cardNo);
        String bcrypt = passwordEncoder.encode(req.pin1);
        CardPaswwordDto rec = new CardPaswwordDto();
        rec.setMemberNo(memberNo);
        rec.setCardNo(cardNo);
        rec.setPinPhc(bcrypt);
        mapper.insert(rec);

        // 2) 카드 신청 상태 갱신
        if (req.applicationNo != null) {
        	cardApplyDao.updateApplicationStatusByAppNo(req.applicationNo, "CARD_PW_SET");
        }

        return ResponseEntity.ok(Map.of(
            "ok", true,
            "message", "PIN이 저장되고 신청 상태가 PIN_SET으로 변경되었습니다."
        ));
    }
}

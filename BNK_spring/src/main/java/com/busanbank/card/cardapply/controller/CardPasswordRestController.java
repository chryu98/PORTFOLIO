package com.busanbank.card.cardapply.controller;

import com.busanbank.card.cardapply.dao.CardPasswordMapper;
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
    private final PasswordEncoder passwordEncoder;

    public CardPasswordRestController(CardPasswordMapper mapper,
                                      PasswordEncoder passwordEncoder) {
        this.mapper = mapper;
        this.passwordEncoder = passwordEncoder;
    }

    // 요청 DTO (저장 전용)
    public static class SetPinReq { public String pin1; public String pin2; }

    /**
     * (기존) 세션에서 memberNo 조회
     */
    private Long sessionMemberNo(HttpSession session) {
        if (session == null) return null;
        Object s = session.getAttribute("loginMemberNo");
        if (s instanceof Integer i) return i.longValue();
        if (s instanceof Long l) return l;
        return null;
    }

    /**
     * ✅ 커스텀 JWT 기반: SecurityContext의 Authentication에서 memberNo 추출
     * - 1) principal.getMemberNo() (커스텀 UserDetails/Principal이 제공한다면)
     * - 2) auth.getName()이 숫자면 사용
     * - 3) auth.getDetails()가 Map이고 "memberNo" 키가 있으면 사용
     * - 실패 시 null (아래 setPin에서 세션 fallback 시도)
     */
    private Long resolveMemberNoFromAuth() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) return null;

        Object principal = auth.getPrincipal();

        // 1) 커스텀 UserDetails/Principal에 getMemberNo()가 있다면 (리플렉션으로 안전하게 시도)
        try {
            var m = principal.getClass().getMethod("getMemberNo");
            Object val = m.invoke(principal);
            if (val instanceof Number n) return n.longValue();
            if (val instanceof String s && s.matches("\\d+")) return Long.parseLong(s);
        } catch (NoSuchMethodException ignore) {
            // 메서드가 없을 수 있음 → 다음 단계로
        } catch (Exception ignore) {
            // 접근/호출 예외는 무시하고 다음 단계로
        }

        // 2) username이 숫자면 그걸 memberNo로 사용 (간편 fallback)
        String name = auth.getName();
        if (name != null && name.matches("\\d+")) {
            return Long.parseLong(name);
        }

        // 3) details에 담아둔 경우 (ex: Map에 넣어둠)
        Object details = auth.getDetails();
        if (details instanceof Map<?, ?> m) {
            Object v = m.get("memberNo");
            if (v instanceof Number n) return n.longValue();
            if (v instanceof String s && s.matches("\\d+")) return Long.parseLong(s);
        }

        return null;
    }

    /** PIN 저장(덮어쓰기): (memberNo, cardNo) 기존행 삭제 후 1행만 저장 */
    @PostMapping("/{cardNo}/pin")
    @Transactional
    public ResponseEntity<?> setPin(@PathVariable("cardNo") long cardNo,
                                    @RequestBody SetPinReq req,
                                    HttpSession session) {
        // 1) 우선 JWT(커스텀 인증)에서 memberNo 추출
        Long memberNo = resolveMemberNoFromAuth();

        // 2) 그래도 없으면 (과거 호환) 세션에서 시도
        if (memberNo == null) {
            memberNo = sessionMemberNo(session);
        }

        if (memberNo == null) {
            return ResponseEntity.status(401).body(Map.of("ok", false, "message", "로그인이 필요합니다."));
        }

        if (req == null || req.pin1 == null || req.pin2 == null) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "입력 누락"));
        }

        if (!req.pin1.equals(req.pin2) || !req.pin1.matches("^\\d{4,6}$")) {
            return ResponseEntity.ok(Map.of("ok", false, "message", "PIN은 숫자 4~6자리, 두 번 동일히 입력"));
        }

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

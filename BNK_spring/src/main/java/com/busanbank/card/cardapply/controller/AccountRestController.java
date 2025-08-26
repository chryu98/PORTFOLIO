// src/main/java/com/busanbank/card/cardapply/controller/AccountRestController.java
package com.busanbank.card.cardapply.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import com.busanbank.card.cardapply.dao.AccountMapper;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.AccountDto;
import com.busanbank.card.cardapply.util.AccountNumberGenerator;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/card/apply/api/accounts")
public class AccountRestController {

    private final AccountMapper accountMapper;
    private final PasswordEncoder passwordEncoder;
    private final IUserDao userDao;
    private final ICardApplyDao cardApplyDao; // ✅ 상태 갱신용 주입

    public AccountRestController(AccountMapper accountMapper,
                                 PasswordEncoder passwordEncoder,
                                 IUserDao userDao,
                                 ICardApplyDao cardApplyDao) {
        this.accountMapper = accountMapper;
        this.passwordEncoder = passwordEncoder;
        this.userDao = userDao;
        this.cardApplyDao = cardApplyDao;
    }

    private ResponseEntity<Map<String,Object>> unauthorized() {
        Map<String,Object> body = new HashMap<>();
        body.put("success", false);
        body.put("message", "로그인이 필요합니다.");
        return ResponseEntity.status(401).body(body);
    }

    /** 세션 또는 SecurityContext에서 현재 사용자 */
    private UserDto currentUser(HttpSession session) {
        Object s = session.getAttribute("loginMemberNo");
        if (s instanceof Integer i) {
            UserDto u = userDao.findByMemberNo(i);
            if (u != null) return u;
        } else if (s instanceof Long l) {
            UserDto u = userDao.findByMemberNo(l.intValue());
            if (u != null) return u;
        }

        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || !a.isAuthenticated() || "anonymousUser".equals(a.getPrincipal())) return null;

        Object p = a.getPrincipal();
        try {
            if (p instanceof com.busanbank.card.user.config.CustomUserDetails cud) {
                Integer memberNo = cud.getMemberNo();
                if (memberNo != null) {
                    UserDto u = userDao.findByMemberNo(memberNo);
                    if (u != null) return u;
                }
            }
        } catch (Throwable ignore) {}

        try {
            if (p instanceof org.springframework.security.core.userdetails.User u0) {
                UserDto u = userDao.findByUsername(u0.getUsername());
                if (u != null) return u;
            }
        } catch (Throwable ignore) {}

        return userDao.findByUsername(a.getName());
    }

    // ---------- 요청 바디 DTO ----------
    public static class CreateIfNoneRequest {
        private Long cardNo;
        private String accountPw;
        private Integer applicationNo; // ✅ 카드 신청 Temp PK

        public Long getCardNo() { return cardNo; }
        public void setCardNo(Long cardNo) { this.cardNo = cardNo; }
        public String getAccountPw() { return accountPw; }
        public void setAccountPw(String accountPw) { this.accountPw = accountPw; }
        public Integer getApplicationNo() { return applicationNo; }
        public void setApplicationNo(Integer applicationNo) { this.applicationNo = applicationNo; }
    }

    public static class SelectRequest {
        private Long acNo;
        public Long getAcNo() { return acNo; }
        public void setAcNo(Long acNo) { this.acNo = acNo; }
    }

    public static class PwSetRequest {
        private String pw1;
        private String pw2;
        private Integer applicationNo; // ✅ 추가

        public String getPw1() { return pw1; }
        public void setPw1(String pw1) { this.pw1 = pw1; }
        public String getPw2() { return pw2; }
        public void setPw2(String pw2) { this.pw2 = pw2; }
        public Integer getApplicationNo() { return applicationNo; }
        public void setApplicationNo(Integer applicationNo) { this.applicationNo = applicationNo; }
    }

    public static class VerifyRequest {
        private String password;
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    // ---------- 상태 조회 ----------
    @GetMapping("/state")
    public ResponseEntity<Map<String,Object>> state(HttpSession session) {
        UserDto user = currentUser(session);
        if (user == null) return unauthorized();

        Long memberNo = Long.valueOf(user.getMemberNo());
        List<AccountDto> actives = accountMapper.findActiveByMemberNo(memberNo);

        Map<String,Object> res = new HashMap<>();
        res.put("success", true);
        res.put("hasAccount", !actives.isEmpty());
        res.put("accounts", actives);
        return ResponseEntity.ok(res);
    }

    // ---------- 없으면 생성 ----------
    @PostMapping("/create-if-none")
    @Transactional
    public ResponseEntity<Map<String,Object>> createIfNone(@RequestBody(required = false) CreateIfNoneRequest req,
                                                           HttpSession session) {
        UserDto user = currentUser(session);
        if (user == null) return unauthorized();

        Long memberNo = Long.valueOf(user.getMemberNo());
        Map<String,Object> res = new HashMap<>();

        if (accountMapper.countCreatedWithinDays(memberNo, 20) > 0) {
            res.put("created", false);
            res.put("message", "최근 20일 이내 계좌를 발급받으셨습니다. 이후에 다시 시도해주세요.");
            return ResponseEntity.ok(res);
        }

        String accountNumber = generateUniqueAccNum();

        AccountDto dto = new AccountDto();
        dto.setMemberNo(memberNo);
        dto.setCardNo(req != null ? req.getCardNo() : null);
        dto.setAccountNumber(accountNumber);

        String rawPw = (req != null ? req.getAccountPw() : null);
        dto.setAccountPw((rawPw == null || rawPw.isBlank()) ? null : passwordEncoder.encode(rawPw));

        dto.setStatus("ACTIVE");
        accountMapper.insert(dto);

        // ✅ 카드 신청 상태 갱신
        if (req != null && req.getApplicationNo() != null) {
            cardApplyDao.updateApplicationStatusByAppNo(req.getApplicationNo(), "ACCOUNT_CREATED");
        }

        res.put("created", true);
        res.put("message", "계좌가 생성되었습니다.");
        res.put("account", dto);
        return ResponseEntity.ok(res);
    }

    // ---------- 자동 생성 ----------
    @PostMapping("/auto-create")
    @Transactional
    public ResponseEntity<Map<String,Object>> autoCreate(@RequestBody(required = false) Map<String,Object> body,
                                                         HttpSession session) {
        UserDto user = currentUser(session);
        if (user == null) return unauthorized();

        Long memberNo = Long.valueOf(user.getMemberNo());

        if (accountMapper.countCreatedWithinDays(memberNo, 20) > 0) {
            return ResponseEntity.ok(Map.of(
                "created", false,
                "message", "최근 20일 내에 계좌가 발급되어 새로운 계좌를 생성할 수 없습니다."
            ));
        }

        Long cardNo = null;
        if (body != null && body.get("cardNo") != null) {
            try { cardNo = Long.valueOf(String.valueOf(body.get("cardNo"))); } catch (Exception ignore) {}
        }

        String accountNumber = generateUniqueAccNum();

        AccountDto dto = new AccountDto();
        dto.setMemberNo(memberNo);
        dto.setCardNo(cardNo);
        dto.setAccountNumber(accountNumber);
        dto.setAccountPw(null);
        dto.setStatus("ACTIVE");
        accountMapper.insert(dto);

        Map<String,Object> res = new HashMap<>();
        res.put("created", true);
        res.put("next", "set-password");
        res.put("message", "계좌가 자동 생성되었습니다. 비밀번호를 설정해주세요.");
        res.put("account", dto);
        return ResponseEntity.ok(res);
    }

    // ---------- 비밀번호 설정 ----------
    @PostMapping("/{acNo}/set-password")
    @Transactional
    public ResponseEntity<Map<String,Object>> setPassword(
            @PathVariable("acNo") Long acNo,
            @RequestBody PwSetRequest req,
            HttpSession session) {

        UserDto user = currentUser(session);
        if (user == null) return unauthorized();

        Map<String,Object> res = new HashMap<>();
        if (req == null || req.getPw1() == null || req.getPw2() == null
                || !req.getPw1().equals(req.getPw2())
                || !req.getPw1().matches("^\\d{4,6}$")) {
            res.put("ok", false);
            res.put("message", "비밀번호는 숫자 4~6자리로 두 번 동일하게 입력해주세요.");
            return ResponseEntity.ok(res);
        }

        AccountDto dto = accountMapper.findById(acNo);
        Long loginMemberNo = Long.valueOf(user.getMemberNo());
        if (dto == null || !"ACTIVE".equals(dto.getStatus())
                || !Objects.equals(dto.getMemberNo(), loginMemberNo)) {
            res.put("ok", false);
            res.put("message", "본인 계좌가 아니거나 사용할 수 없습니다.");
            return ResponseEntity.ok(res);
        }

        int updated = accountMapper.updatePasswordByOwner(acNo, loginMemberNo, passwordEncoder.encode(req.getPw1()));
        if (updated == 0) {
            res.put("ok", false);
            res.put("message", "비밀번호 설정에 실패했습니다.");
            return ResponseEntity.ok(res);
        }

        // ✅ 카드 신청 상태 갱신 (바디에서 받음)
        if (req.getApplicationNo() != null) {
            cardApplyDao.updateApplicationStatusByAppNo(req.getApplicationNo(), "ACCOUNT_PW_SET");
        }

        res.put("ok", true);
        res.put("message", "비밀번호가 설정되었습니다.");
        return ResponseEntity.ok(res);
    }

    // ---------- 기존 계좌 비밀번호 검증 ----------
    @PostMapping("/{acNo}/verify-and-select")
    public ResponseEntity<Map<String,Object>> verifyAndSelect(@PathVariable("acNo") Long acNo,
                                                              @RequestBody VerifyRequest body,
                                                              HttpSession session) {
        UserDto user = currentUser(session);
        if (user == null) return unauthorized();

        if (body == null || body.getPassword() == null || body.getPassword().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("ok", false, "message", "비밀번호를 입력하세요."));
        }

        AccountDto dto = accountMapper.findById(acNo);
        if (dto == null || !"ACTIVE".equals(dto.getStatus())
            || !Objects.equals(dto.getMemberNo(), Long.valueOf(user.getMemberNo()))) {
            return ResponseEntity.status(403).body(Map.of("ok", false, "message", "계좌를 사용할 수 없습니다."));
        }

        if (dto.getAccountPw() == null || !passwordEncoder.matches(body.getPassword(), dto.getAccountPw())) {
            return ResponseEntity.status(401).body(Map.of("ok", false, "message", "인증 실패"));
        }

        session.setAttribute("CURRENT_ACCOUNT_NO", acNo);
        return ResponseEntity.ok(Map.of("ok", true, "message", "계좌가 선택되었습니다."));
    }

    // ---------- 단순 선택 ----------
    @PostMapping("/select")
    public ResponseEntity<Map<String,Object>> select(@RequestBody SelectRequest req,
                                                     HttpSession session) {
        UserDto user = currentUser(session);
        if (user == null) return unauthorized();

        Map<String,Object> res = new HashMap<>();
        if (req == null || req.getAcNo() == null) {
            res.put("ok", false);
            res.put("message", "acNo가 누락되었습니다.");
            return ResponseEntity.ok(res);
        }

        AccountDto dto = accountMapper.findById(req.getAcNo());
        Long loginMemberNo = Long.valueOf(user.getMemberNo());
        if (dto == null || !"ACTIVE".equals(dto.getStatus())
                || !Objects.equals(dto.getMemberNo(), loginMemberNo)) {
            res.put("ok", false);
            res.put("message", "선택한 계좌를 사용할 수 없습니다.");
            return ResponseEntity.ok(res);
        }

        session.setAttribute("CURRENT_ACCOUNT_NO", req.getAcNo());
        res.put("ok", true);
        res.put("message", "계좌가 선택되었습니다.");
        return ResponseEntity.ok(res);
    }

    // ---------- 해지 ----------
    @PostMapping("/{acNo}/close")
    @Transactional
    public ResponseEntity<Map<String,Object>> close(@PathVariable("acNo") Long acNo,
                                                    HttpSession session) {
        UserDto user = currentUser(session);
        if (user == null) return unauthorized();

        Map<String,Object> res = new HashMap<>();
        AccountDto dto = accountMapper.findById(acNo);

        Long loginMemberNo = Long.valueOf(user.getMemberNo());
        if (dto == null || !Objects.equals(dto.getMemberNo(), loginMemberNo)) {
            res.put("closed", false);
            res.put("message", "본인 계좌가 아니거나 존재하지 않습니다.");
            return ResponseEntity.ok(res);
        }

        accountMapper.close(acNo);
        res.put("closed", true);
        res.put("message", "계좌가 해지되었습니다.");
        return ResponseEntity.ok(res);
    }

    // ---------- 내부 유틸 ----------
    private String generateUniqueAccNum() {
        for (int i = 0; i < 30; i++) {
            String cand = AccountNumberGenerator.generate(); // 112 시작, 13자리
            if (!cand.startsWith("112") || cand.length() != 13 || !cand.matches("\\d{13}")) continue;
            if (accountMapper.findByAccountNumber(cand) == null) return cand;
        }
        throw new IllegalStateException("계좌번호 생성 실패(중복 과다)");
    }
}

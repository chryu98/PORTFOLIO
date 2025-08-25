package com.busanbank.card.cardapply.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity; // 200/ok
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;   // prefill
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.card.dao.CardDao;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.ApplicationPersonTempDto;
import com.busanbank.card.cardapply.dto.CardApplicationTempDto;
import com.busanbank.card.cardapply.dto.ContactInfoDto;
import com.busanbank.card.cardapply.dto.JobInfoDto;
import com.busanbank.card.cardapply.dto.UserInputInfoDto;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/card/apply/api")
@Slf4j
public class CardApplyRestController {

    @Autowired private IUserDao userDao;
    @Autowired private CardDao cardDao;
    @Autowired private ICardApplyDao cardApplyDao;
    
    /** 현재 인증된 사용자 조회 (JWT 기반) */
    private UserDto currentUser() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || !a.isAuthenticated() || "anonymousUser".equals(a.getPrincipal())) return null;

        Object p = a.getPrincipal();

        // 1) 우리 커스텀 UserDetails 에 memberNo 가 있으면 가장 확실
        try {
            if (p instanceof com.busanbank.card.user.config.CustomUserDetails cud) {
                Integer memberNo = cud.getMemberNo();
                if (memberNo != null) {
                    UserDto byNo = userDao.findByMemberNo(memberNo);
                    if (byNo != null) return byNo;
                }
            }
        } catch (Throwable ignore) {}

        // 2) 기본 UserDetails → username
        try {
            if (p instanceof org.springframework.security.core.userdetails.User u) {
                UserDto byUsername = userDao.findByUsername(u.getUsername());
                if (byUsername != null) return byUsername;
            }
        } catch (Throwable ignore) {}

        // 3) 마지막 fallback: Authentication.getName()
        return userDao.findByUsername(a.getName());
    }

    /** 프리필(이름, 주민번호 앞6자리) */
    @GetMapping("/prefill")
    public ResponseEntity<Map<String, Object>> prefill() {
        Map<String, Object> res = new HashMap<>();

        UserDto u = currentUser();
        if (u == null) {
            res.put("success", false);
            res.put("message", "로그인이 필요합니다.");
            return ResponseEntity.status(401).body(res);
        }

        Map<String, Object> profile = new HashMap<>();
        profile.put("name",     u.getName());     // 한글 이름
        profile.put("rrnFront", u.getRrnFront()); // 앞 6자리

        res.put("success", true);
        res.put("profile", profile);
        return ResponseEntity.ok(res);
    }

    /** Step1: 검증 + 임시저장(application/person temp insert) */
    @PostMapping("/validateInfo")
    public ResponseEntity<Map<String, Object>> validateInfo(@RequestBody UserInputInfoDto in) throws Exception {
        Map<String, Object> result = new HashMap<>();

        UserDto loginUser = currentUser();
        if (loginUser == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return ResponseEntity.status(401).body(result);
        }

        // ----- 입력값 기본 검증 -----
        if (isNullOrEmpty(in.getName()))                           return fail(result, "성명을 입력해주세요.");
        if (isNullOrEmpty(in.getEngFirstName()) || isNullOrEmpty(in.getEngLastName()))
                                                                   return fail(result, "영문명을 입력해주세요.");
        if (isNullOrEmpty(in.getRrnFront()) || isNullOrEmpty(in.getRrnBack()))
                                                                   return fail(result, "주민등록번호를 입력해주세요.");
        if (!isValidRRN(in.getRrnFront(), in.getRrnBack()))        return fail(result, "유효하지 않은 주민등록번호입니다.");
        if (in.getCardNo() == null)                                return fail(result, "cardNo가 누락되었습니다.");

        // ----- DB값과 입력값 정규화 후 비교 -----
        final String inputName     = normName(in.getName());
        final String inputRrnFront = digits(in.getRrnFront()); // 6
        final String inputRrnBack  = digits(in.getRrnBack());  // 7 (성별1 + tail6)

        final String dbName     = normName(loginUser.getName());
        final String dbRrnFront = digits(loginUser.getRrnFront());   // 6
        final String dbGender   = (loginUser.getRrnGender() == null) ? "" : loginUser.getRrnGender().trim();
        final String dbTail     = AESUtil.decrypt(loginUser.getRrnTailEnc()); // 6

        boolean nameMatch  = dbName.equals(inputName);
        boolean frontMatch = dbRrnFront.equals(inputRrnFront);

     // (이미 위에서 계산했다면 생략) 복호화
        final String inputBack = digits(in.getRrnBack()); // "1234567" 형태

        final boolean lenOk    = inputBack.length() == 7;
        final boolean genderOk = !dbGender.isEmpty() && lenOk && inputBack.charAt(0) == dbGender.charAt(0);
        final boolean tailOk   = lenOk && dbTail != null && inputBack.substring(1).equals(dbTail);
        final boolean tailDigitsOk = dbTail != null && dbTail.matches("\\d{6}");

        // ✅ 반드시 return 전에 찍어야 확인 가능
        log.warn("[DBG] backMatch parts: lenOk={}, genderOk={}, tailOk={}, tailDigitsOk={}",
                lenOk, genderOk, tailOk, tailDigitsOk);
        log.warn("[DBG] expected={} input={}", dbGender + "******", maskRrnBack(inputBack));

        final boolean backMatch = genderOk && tailOk;

        log.info("[validateInfo] nameMatch={}, frontMatch={}, backMatch={}, inBack={}, dbBack={}",
                nameMatch, frontMatch, backMatch, maskRrnBack(inputBack), dbGender + "******");

        if (!(nameMatch && frontMatch && backMatch)) {
            // 원인 힌트까지 주고 싶으면(개발용)
            final String reason = !nameMatch ? "이름 불일치"
                              : !frontMatch ? "앞6 불일치"
                              : !lenOk ? "뒤7 길이 오류"
                              : !genderOk ? "성별코드 불일치"
                              : !tailDigitsOk ? "DB 뒤6 복호화 비정상"
                              : "뒤6 불일치";
            return fail(result, "입력한 정보가 회원 정보와 일치하지 않습니다. ("+reason+")");
        }
        
        
        String enc = "aXK4QxRiQqnsoaiushyuLg==";
        String tail = AESUtil.decrypt(enc);
        System.out.println("TAIL=" + tail + " len=" + (tail==null?0:tail.length()));
        System.out.println("digits=" + (tail != null && tail.matches("\\d{6}")));

        // ----- 임시 저장: 헤더 -----
        Long cardNo = in.getCardNo();
        CardApplicationTempDto app = new CardApplicationTempDto();
        app.setMemberNo(loginUser.getMemberNo());
        app.setCardNo(cardNo);
        app.setStatus("DRAFT");

        String cardType = cardDao.selectCardTypeById(cardNo);
        app.setIsCreditCard("신용".equals(cardType) ? "Y" : "N");
        app.setHasAccountAtKyc("N");
        app.setIsShortTermMulti("N");
        cardApplyDao.insertCardApplicationTemp(app);

        // ----- 임시 저장: 신청자 (검증된 DB값으로 저장) -----
        ApplicationPersonTempDto person = new ApplicationPersonTempDto();
        person.setApplicationNo(app.getApplicationNo());
        person.setName(in.getName());
        person.setNameEng(in.getEngFirstName() + " " + in.getEngLastName());

        person.setRrnFront(dbRrnFront);                 // ← DB 앞6
        person.setRrnGender(dbGender);                  // ← DB 성별
        person.setRrnTailEnc(loginUser.getRrnTailEnc()); // ← DB 암호문 그대로

        cardApplyDao.insertApplicationPersonTemp(person);
        
        // 카드 앱플리케이션 탬프 상태 추가
        cardApplyDao.updateApplicationStatusByAppNo(app.getApplicationNo(), "INFO_INPUT");

        // 응답
        result.put("success", true);
        result.put("message", "검증 완료");
        result.put("applicationNo", app.getApplicationNo());
        result.put("isCreditCard", app.getIsCreditCard());
        return ResponseEntity.ok(result);
    }

    /** 신청 시작(/start) : app temp 헤더만 생성 */
    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> start(@RequestBody Map<String, Object> body) throws Exception {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = (auth != null ? auth.getName() : "anonymous");
        String roles    = (auth != null ? auth.getAuthorities().toString() : "[]");
        log.info("[apply/start] request by user={}, roles={}, body={}", username, roles, body);

        UserDto loginUser = currentUser();
        if (loginUser == null) {
            log.warn("[apply/start] unauthorized user (no principal)");
            Map<String, Object> res = new HashMap<>();
            res.put("success", false);
            res.put("message", "로그인이 필요합니다.");
            return ResponseEntity.status(401).body(res);
        }

        Object raw = body.get("cardNo");
        if (raw == null) {
            log.warn("[apply/start] memberNo={} but cardNo missing", loginUser.getMemberNo());
            return fail(new HashMap<>(), "cardNo가 누락되었습니다.");
        }
        Long cardNo = Long.valueOf(raw.toString());
        log.info("[apply/start] memberNo={}, username={}, cardNo={}",
                loginUser.getMemberNo(), loginUser.getUsername(), cardNo);

        CardApplicationTempDto app = new CardApplicationTempDto();
        app.setMemberNo(loginUser.getMemberNo());
        app.setCardNo(cardNo);
        app.setStatus("DRAFT");

        String cardType = cardDao.selectCardTypeById(cardNo);
        app.setIsCreditCard("신용".equals(cardType) ? "Y" : "N");
        app.setHasAccountAtKyc("N");
        app.setIsShortTermMulti("N");
        cardApplyDao.insertCardApplicationTemp(app);

        log.info("[apply/start] application created: applicationNo={}, isCreditCard={}",
                app.getApplicationNo(), app.getIsCreditCard());

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("applicationNo", app.getApplicationNo());
        res.put("isCreditCard", app.getIsCreditCard());
        return ResponseEntity.ok(res);
    }

    /** 연락처 검증/저장 */
    @PostMapping("/validateContact")
    public ResponseEntity<Map<String, Object>> validateContact(@RequestBody ContactInfoDto contactInfo) {
        Map<String, Object> result = new HashMap<>();

        if (isNullOrEmpty(contactInfo.getEmail()))  return fail(result, "이메일을 입력해주세요.");
        if (isNullOrEmpty(contactInfo.getPhone()))  return fail(result, "연락처를 입력해주세요.");
        if (!isValidEmail(contactInfo.getEmail()))  return fail(result, "유효한 이메일 형식이 아닙니다.");
        if (!isValidPhone(contactInfo.getPhone()))  return fail(result, "유효한 연락처 형식이 아닙니다. (예: 010-1234-5678)");

        int updated = cardApplyDao.updateApplicationContactTemp(contactInfo);
        if (updated == 0) return fail(result, "임시 신청 정보를 찾을 수 없습니다.");
        
        cardApplyDao.updateApplicationStatusByAppNo(contactInfo.getApplicationNo(), "CONTACT_INPUT");

        result.put("success", true);
        result.put("applicationNo", contactInfo.getApplicationNo());
        return ResponseEntity.ok(result);
    }

    /** KYC/직업 등 저장 */
    @PostMapping("/saveJobInfo")
    public ResponseEntity<Map<String, Object>> saveJobInfo(@RequestBody JobInfoDto jobInfo) {
        Map<String, Object> result = new HashMap<>();

        if (isNullOrEmpty(jobInfo.getJob()))        return fail(result, "직업을 선택하세요.");
        if (isNullOrEmpty(jobInfo.getPurpose()))    return fail(result, "거래 목적을 선택하세요.");
        if (isNullOrEmpty(jobInfo.getFundSource())) return fail(result, "자금 출처를 선택하세요.");

        int updated = cardApplyDao.updateApplicationJobTemp(jobInfo);
        if (updated == 0) return fail(result, "정보 저장에 실패했습니다.");
        
        cardApplyDao.updateApplicationStatusByAppNo(jobInfo.getApplicationNo(), "JOB_INPUT");

        result.put("success", true);
        result.put("applicationNo", jobInfo.getApplicationNo());
        return ResponseEntity.ok(result);
    }

    // ================= helpers =================

    private static boolean isNullOrEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }

    /** 주민번호 유효성(간단) */
    private static boolean isValidRRN(String rrnFront, String rrnBack) {
        if (rrnFront == null || rrnBack == null) return false;
        String f = digits(rrnFront);
        String b = digits(rrnBack);
        if (!f.matches("\\d{6}") || !b.matches("\\d{7}")) return false;

        int mm = Integer.parseInt(f.substring(2, 4));
        int dd = Integer.parseInt(f.substring(4, 6));
        if (mm < 1 || mm > 12) return false;
        java.util.Calendar cal = new java.util.GregorianCalendar(2000, mm - 1, 1);
        int maxDay = cal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH);
        if (dd < 1 || dd > maxDay) return false;

        char g = b.charAt(0);
        return g >= '1' && g <= '4';
    }

    /** 숫자만 남기기 */
    private static String digits(String s) {
        return (s == null) ? "" : s.replaceAll("[^0-9]", "");
    }

    /** 이름 공백 정규화 */
    private static String normName(String s) {
        if (s == null) return "";
        return s.trim().replaceAll("\\s+", " ");
    }

    /** RRn 뒷자리 마스킹: 1****** */
    private static String maskRrnBack(String s) {
        String d = digits(s);
        if (d.isEmpty()) return "";
        return d.charAt(0) + "******";
    }

    private ResponseEntity<Map<String, Object>> fail(Map<String, Object> result, String message) {
        result.put("success", false);
        result.put("message", message);
        return ResponseEntity.ok(result);
    }

    private boolean isValidEmail(String email) {
        return email != null && email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");
    }

    private boolean isValidPhone(String phone) {
        return phone != null && phone.matches("^010-[0-9]{4}-[0-9]{4}$");
    }
}

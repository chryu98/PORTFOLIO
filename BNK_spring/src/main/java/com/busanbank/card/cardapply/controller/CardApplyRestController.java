package com.busanbank.card.cardapply.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity; // 200/ok만 사용
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.card.dao.CardDao;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.ApplicationPersonTempDto;
import com.busanbank.card.cardapply.dto.CardApplicationTempDto;
import com.busanbank.card.cardapply.dto.UserInputInfoDto;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/card/apply/api")
public class CardApplyRestController {

    @Autowired private IUserDao userDao;
    @Autowired private CardDao cardDao;
    @Autowired private ICardApplyDao cardApplyDao;

    @PostMapping("/validateInfo")
    public ResponseEntity<Map<String, Object>> validateInfo(@RequestBody UserInputInfoDto userInputInfo,
                                                            HttpSession session) throws Exception {
        Map<String, Object> result = new HashMap<>();

        // ===========================
        // [DEV ONLY] 로그인 우회
        // TODO: 운영 배포 전 반드시 제거하거나 @Profile("dev")로 제한
        // ===========================
        Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
        if (memberNo == null) memberNo = 1;

        // [운영용 정석 처리]
        // if (memberNo == null) {
        //     result.put("success", false);
        //     result.put("message", "로그인이 필요합니다.");
        //     return ResponseEntity.ok(result); // 401 대신 200 + fail
        // }

        UserDto loginUser = userDao.findByMemberNo(memberNo);
        if (loginUser == null) {
            result.put("success", false);
            result.put("message", "유효하지 않은 회원입니다.");
            return ResponseEntity.ok(result);
        }

        // 입력값 기본 검증
        if (isNullOrEmpty(userInputInfo.getName())) {
            result.put("success", false);
            result.put("message", "성명을 입력해주세요.");
            return ResponseEntity.ok(result);
        }
        if (isNullOrEmpty(userInputInfo.getEngFirstName()) || isNullOrEmpty(userInputInfo.getEngLastName())) {
            result.put("success", false);
            result.put("message", "영문명을 입력해주세요.");
            return ResponseEntity.ok(result);
        }
        if (isNullOrEmpty(userInputInfo.getRrnFront()) || isNullOrEmpty(userInputInfo.getRrnBack())) {
            result.put("success", false);
            result.put("message", "주민등록번호를 입력해주세요.");
            return ResponseEntity.ok(result);
        }
        if (!isValidRRN(userInputInfo.getRrnFront(), userInputInfo.getRrnBack())) {
            result.put("success", false);
            result.put("message", "유효하지 않은 주민등록번호입니다.");
            return ResponseEntity.ok(result);
        }
        if (userInputInfo.getCardNo() == null) {
            result.put("success", false);
            result.put("message", "cardNo가 누락되었습니다.");
            return ResponseEntity.ok(result);
        }

        // 회원 정보와 입력값 일치 검증
        String loginUserRrnBack = loginUser.getRrnGender() + AESUtil.decrypt(loginUser.getRrnTailEnc());
        boolean nameMatch = loginUser.getName().equals(userInputInfo.getName());
        boolean rrnMatch  = loginUser.getRrnFront().equals(userInputInfo.getRrnFront())
                          && loginUserRrnBack.equals(userInputInfo.getRrnBack());
        if (!nameMatch || !rrnMatch) {
            result.put("success", false);
            result.put("message", "입력한 정보가 회원 정보와 일치하지 않습니다.");
            return ResponseEntity.ok(result);
        }

        // 임시 저장 - 신청 헤더 (CARD_APPLICATION_TEMP)
        Long cardNo = userInputInfo.getCardNo();
        CardApplicationTempDto app = new CardApplicationTempDto();
        app.setMemberNo(memberNo);
        app.setCardNo(cardNo);
        app.setStatus("DRAFT");

        String cardType = cardDao.selectCardTypeById(cardNo);
        app.setIsCreditCard("신용".equals(cardType) ? "Y" : "N");
        app.setHasAccountAtKyc("N");
        app.setIsShortTermMulti("N");
        cardApplyDao.insertCardApplicationTemp(app);

        // 임시 저장 - 신청자 정보 (APPLICATION_PERSON_TEMP)
        ApplicationPersonTempDto person = new ApplicationPersonTempDto();
        person.setApplicationNo(app.getApplicationNo());
        person.setName(userInputInfo.getName());
        person.setNameEng(userInputInfo.getEngFirstName() + " " + userInputInfo.getEngLastName());
        person.setRrnFront(userInputInfo.getRrnFront());
        String rrnBack = userInputInfo.getRrnBack();
        person.setRrnGender(rrnBack.substring(0, 1));
        person.setRrnTailEnc(AESUtil.encrypt(rrnBack.substring(1)));
        cardApplyDao.insertApplicationPersonTemp(person);

        // 성공 응답
        result.put("success", true);
        result.put("message", "검증 완료");
        result.put("applicationNo", app.getApplicationNo());
        result.put("isCreditCard", app.getIsCreditCard());
        return ResponseEntity.ok(result);
    }

    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> start(@RequestBody Map<String, Object> body,
                                                     HttpSession session) throws Exception {
        Map<String, Object> res = new HashMap<>();

        // [DEV ONLY] 로그인 우회
        Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
        if (memberNo == null) memberNo = 1; // TODO: dev 전용

        Object raw = body.get("cardNo");
        if (raw == null) {
            res.put("success", false);
            res.put("message", "cardNo가 누락되었습니다.");
            return ResponseEntity.ok(res);
        }
        Long cardNo = Long.valueOf(raw.toString());

        CardApplicationTempDto app = new CardApplicationTempDto();
        app.setMemberNo(memberNo);
        app.setCardNo(cardNo);
        app.setStatus("DRAFT");

        String cardType = cardDao.selectCardTypeById(cardNo);
        app.setIsCreditCard("신용".equals(cardType) ? "Y" : "N");
        app.setHasAccountAtKyc("N");
        app.setIsShortTermMulti("N");

        cardApplyDao.insertCardApplicationTemp(app);

        res.put("success", true);
        res.put("applicationNo", app.getApplicationNo());
        res.put("isCreditCard", app.getIsCreditCard());
        return ResponseEntity.ok(res);
    }

    // ================= helpers =================

    private static boolean isNullOrEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static boolean isValidRRN(String rrnFront, String rrnBack) {
        if (rrnFront == null || rrnBack == null) return false;

        // 자리수 체크
        if (!rrnFront.matches("\\d{6}") || !rrnBack.matches("\\d{7}")) return false;

        // 생년월일 유효성
        int month = Integer.parseInt(rrnFront.substring(2, 4));
        int day   = Integer.parseInt(rrnFront.substring(4, 6));
        if (month < 1 || month > 12) return false;
        java.util.Calendar cal = new java.util.GregorianCalendar(2000, month - 1, 1);
        int maxDay = cal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH);
        if (day < 1 || day > maxDay) return false;

        // 성별코드 1~4
        char genderCode = rrnBack.charAt(0);
        return genderCode >= '1' && genderCode <= '4';
    }
}

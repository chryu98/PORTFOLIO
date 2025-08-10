package com.busanbank.card.cardapply.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.cardapply.dto.UserInputInfoDto;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/card/apply/api")
public class CardApplyRestController {

	@Autowired
	private IUserDao userDao;
	
	@PostMapping("/validateInfo")
	public ResponseEntity<Map<String, Object>> validateInfo(@RequestBody UserInputInfoDto userInputInfo,
										  HttpSession session) throws Exception{
		Map<String, Object> result = new HashMap<>();
		
		//로그인 여부 확인
        Integer memberNo = (Integer) session.getAttribute("memberNo");
        if (memberNo == null) {
            result.put("success", false);
            result.put("message", "로그인이 필요합니다.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
        
        UserDto loginUser = userDao.findByMemberNo(memberNo);
        
        //이름 null 체크
        if(isNullOrEmpty(userInputInfo.getName())) {
        	result.put("success", false);
        	result.put("message", "성명을 입력해주세요.");
        	return ResponseEntity.badRequest().body(result);
        }
        //영문 이름 null 체크
        if(isNullOrEmpty(userInputInfo.getEngFirstName()) || isNullOrEmpty(userInputInfo.getEngLastName())) {
        	result.put("success", false);
        	result.put("message", "영문명을 입력해주세요.");
        	return ResponseEntity.badRequest().body(result);
        }
        //주민등록번호 null 체크
        if(isNullOrEmpty(userInputInfo.getRrnFront()) ||
                isNullOrEmpty(userInputInfo.getRrnBack())) {
        	result.put("success", false);
        	result.put("message", "주민등록번호를 입력해주세요.");
        	return ResponseEntity.badRequest().body(result);
        }
        //주민등록번호 유효성 검사
        if (!isValidRRN(userInputInfo.getRrnFront(), userInputInfo.getRrnBack())) {
            result.put("success", false);
            result.put("message", "유효하지 않은 주민등록번호입니다.");
            return ResponseEntity.badRequest().body(result);
        }
        
        //DB의 로그인 사용자 정보와 비교
        String loginUserRrnBack = loginUser.getRrnGender() + AESUtil.decrypt(loginUser.getRrnTailEnc());
        
        boolean nameMatch = loginUser.getName().equals(userInputInfo.getName());
        boolean rrnMatch = loginUser.getRrnFront().equals(userInputInfo.getRrnFront())
                			&& loginUserRrnBack.equals(userInputInfo.getRrnBack());

        if (!nameMatch || !rrnMatch) {
            result.put("success", false);
            result.put("message", "입력한 정보가 회원 정보와 일치하지 않습니다.");
            return ResponseEntity.ok(result);
        }

        //통과
        result.put("success", true);
        result.put("message", "검증 완료");
        return ResponseEntity.ok(result);
	}
	
	//null 체크
    private boolean isNullOrEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    //주민등록번호 유효성 검사
    private boolean isValidRRN(String rrnFront, String rrnBack) {
        // 자리수 체크
        if (!rrnFront.matches("\\d{6}") || !rrnBack.matches("\\d{7}")) {
            return false;
        }

        // 생년월일 유효성 체크
        int year = Integer.parseInt(rrnFront.substring(0, 2));
        int month = Integer.parseInt(rrnFront.substring(2, 4));
        int day = Integer.parseInt(rrnFront.substring(4, 6));

        if (month < 1 || month > 12) return false;
        int daysInMonth = new java.util.GregorianCalendar(2000, month - 1, 1)
                .getActualMaximum(java.util.Calendar.DAY_OF_MONTH);
        if (day < 1 || day > daysInMonth) return false;

        // 성별코드(뒷자리 첫 숫자) 유효성 체크: 1~4
        char genderCode = rrnBack.charAt(0);
        if (genderCode < '1' || genderCode > '4') return false;

        return true;
    }
}

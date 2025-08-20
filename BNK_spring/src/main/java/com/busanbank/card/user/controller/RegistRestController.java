package com.busanbank.card.user.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.TermDto;
import com.busanbank.card.user.dto.TermsAgreementDto;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.dto.UserJoinDto;
import com.busanbank.card.user.service.JoinService;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/user/api/regist")
public class RegistRestController {

	@Autowired
	private BCryptPasswordEncoder bCryptPasswordEncoder;
	@Autowired
	private IUserDao userDao;
	@Autowired
	private JoinService joinService;
	
	//회원유형선택
	@PostMapping("/selectMemberType")
	public ResponseEntity<?> registForm(@RequestBody Map<String, String> requestBody,
										HttpSession session) {
		Map<String, Object> response = new HashMap<>();
		
		String username = (String) session.getAttribute("loginUsername");
		if(username != null) {
			response.put("message", "이미 로그인된 사용자입니다.");
            response.put("redirectUrl", "/");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
		}
		
		String role = requestBody.get("role");
        if (role != null && !role.isEmpty()) {
            session.setAttribute("role", role);
        }
        else {
            response.put("message", "회원유형이 선택되지 않았습니다.");
            return ResponseEntity.badRequest().body(response);
        }
        
		response.put("redirectUrl", "/user/regist/terms");
        return ResponseEntity.ok(response);
	}
	
	//약관 동의
	@PostMapping("/terms")
	public ResponseEntity<?> terms(@RequestBody Map<String, String> paramMap, HttpSession session) {

		Map<String, Object> response = new HashMap<>();

	    String role = (String) session.getAttribute("role");
	    if (role == null) {
	        response.put("message", "회원유형이 선택되지 않았습니다.");
	        response.put("redirectUrl", "/user/regist/selectMemberType");
	        return ResponseEntity.badRequest().body(response);
	    }

	    List<TermDto> terms = userDao.findAllTerms();

	    for (TermDto term : terms) {
	        String agreeYn = paramMap.get("terms" + term.getTermNo());
	        if (agreeYn == null) {
	            agreeYn = "N";
	        }
	        term.setAgreeYn(agreeYn);
	    }
	    
	    for (TermDto term : terms) {
	        if ("Y".equals(term.getIsRequired()) && !"Y".equals(term.getAgreeYn())) {

	        	response.put("message", "필수 약관에 모두 동의해 주세요.");

	       
	            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
	        }
	    }

	    response.put("redirectUrl", "/user/regist/userRegistForm");
	    return ResponseEntity.ok(response);
	}
	
	//정보입력 폼 페이지
	@PostMapping("/userRegistForm")
	public String userRegistForm(
	    @RequestParam Map<String, String> paramMap,
	    @RequestParam("role") String role,
	    Model model) {

	    List<TermDto> terms = userDao.findAllTerms();

	    for (TermDto term : terms) {
	        String agreeYn = paramMap.get("terms" + term.getTermNo());
	        if (agreeYn == null) {
	            agreeYn = "N";
	        }
	        term.setAgreeYn(agreeYn);
	    }

	    for (TermDto term : terms) {
	        if ("Y".equals(term.getIsRequired()) && !"Y".equals(term.getAgreeYn())) {
	            model.addAttribute("terms", terms);
	            model.addAttribute("role", role);
	            model.addAttribute("msg", "필수 약관에 동의해 주세요.");
	            return "user/terms";
	        }
	    }

	    model.addAttribute("terms", terms);
	    model.addAttribute("role", role);
	    return "user/userRegistForm";
	}
	
	//아이디 중복확인
	@PostMapping("/check-username")
	public Map<String, Object> checkUsername(@RequestParam("username")String username) {
		Map<String, Object> result = new HashMap<>();
		
		UserDto user = userDao.findByUsername(username);
		if(user != null) {
			result.put("valid", false);
			result.put("msg", "이미 사용중인 아이디입니다.");
		} else {
			result.put("valid", true);
			result.put("msg", "사용 가능한 아이디입니다.");
		}
		
		return result;
	}
	
	//유효성 검사 및 insert
	@PostMapping("/submit")

	public ResponseEntity<?> regist(@RequestBody UserJoinDto joinUser,
									HttpSession session) {


		Map<String, Object> response = new HashMap<>();
		
		String validationMsg = joinService.validateJoinUser(joinUser);
		if(validationMsg != null) {
			response.put("success", false);
            response.put("msg", validationMsg);
            return ResponseEntity.badRequest().body(response);
		}
		
		UserDto user = new UserDto();
		user.setName(joinUser.getName());
		user.setUsername(joinUser.getUsername());

		String encodedPassword = bCryptPasswordEncoder.encode(joinUser.getPassword());
		user.setPassword(encodedPassword);
		
		String rrn_gender = joinUser.getRrnBack().substring(0, 1);
		String rrn_tail = joinUser.getRrnBack().substring(1);
		String encryptedRrnTail;
		try {
			encryptedRrnTail = AESUtil.encrypt(rrn_tail);
		} catch (Exception e) {
			response.put("success", false);
            response.put("msg", "회원가입 중 오류가 발생했습니다. 다시 시도해주세요.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
		}
		
		//주민등록번호
		if(joinUser.getRrnBack() == null || joinUser.getRrnBack().length() != 7) {
		    response.put("success", false);
		    response.put("msg", "주민등록번호 뒷자리를 올바르게 입력해주세요.");
		    return ResponseEntity.badRequest().body(response);
		}
		
		user.setRrnFront(joinUser.getRrnFront());
		user.setRrnGender(rrn_gender);
		user.setRrnTailEnc(encryptedRrnTail);
		
		//주소
		user.setZipCode(joinUser.getZipCode());
		String address1 = joinUser.getAddress1() + joinUser.getExtraAddress();
		user.setAddress1(address1);
		user.setAddress2(joinUser.getAddress2());
		
		//String role = (String) session.getAttribute("role");
		user.setRole(joinUser.getRole());
		
		userDao.insertMember(user);
		
		UserDto registUser = userDao.findByUsername(user.getUsername());
		
		TermsAgreementDto term1Agree = new TermsAgreementDto();
		term1Agree.setMemberNo(registUser.getMemberNo());
		term1Agree.setTermNo(1);
		
		userDao.insertTermsAgreement(term1Agree);

		TermsAgreementDto term2Agree = new TermsAgreementDto();
		term2Agree.setMemberNo(registUser.getMemberNo());
		term2Agree.setTermNo(2);
		
		userDao.insertTermsAgreement(term2Agree);
		
		session.removeAttribute("role");

		response.put("success", true);
        response.put("msg", "회원가입이 완료되었습니다.");
        return ResponseEntity.ok(response);
	}
	
	//플러터 약관
	@GetMapping("/getTerms")
	public ResponseEntity<?> getTerms() {
        List<TermDto> terms = userDao.findAllTerms();

        return ResponseEntity.ok(terms);
    } 
}

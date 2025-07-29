package com.busanbank.card.user.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.TermDto;
import com.busanbank.card.user.dto.TermsAgreementDto;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.dto.UserJoinDto;
import com.busanbank.card.user.service.JoinService;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/regist")
public class RegistController {

	@Autowired
	private BCryptPasswordEncoder bCryptPasswordEncoder;
	@Autowired
	private IUserDao userDao;
	@Autowired
	private JoinService joinService;
	
	//회원유형선택
	@GetMapping("/selectMemberType")
	public String registForm(HttpSession session, Model model,
							 RedirectAttributes rttr) {
		
		String username = (String) session.getAttribute("loginUsername");
		if(username != null) {
			rttr.addFlashAttribute("msg", "이미 로그인된 사용자입니다.");
			return "redirect:/";
		}
		
		return "user/selectMemberType";
	}
	
	//약관 동의
	@PostMapping("/terms")
	public String terms(@RequestParam("role") String role,
	                    Model model,
	                    HttpSession session,
	                    RedirectAttributes rttr) {

		String username = (String) session.getAttribute("loginUsername");
		if (username != null) {
			rttr.addFlashAttribute("msg", "이미 로그인된 사용자입니다.");
			return "redirect:/";
		}

		List<TermDto> terms = userDao.findAllTerms();
		for (TermDto term : terms) {
			term.setAgreeYn("N");
		}

		model.addAttribute("terms", terms);
		model.addAttribute("role", role);
		return "user/terms";
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
	@ResponseBody
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
	@PostMapping("/regist")
	public String regist(UserJoinDto joinUser, Model model,
						 RedirectAttributes rttr) {
		
		String validationMsg = joinService.validateJoinUser(joinUser);
		if(validationMsg != null) {
			model.addAttribute("msg", validationMsg);
			return "user/userRegistForm";
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
			model.addAttribute("msg", "회원가입 중 오류가 발생했습니다. 다시 시도해주세요.");
			return "user/userRegistForm";
		}
		
		//주민등록번호
		user.setRrnFront(joinUser.getRrnFront());
		user.setRrnGender(rrn_gender);
		user.setRrnTailEnc(encryptedRrnTail);
		
		//주소
		user.setZipCode(joinUser.getZipCode());
		String address1 = joinUser.getAddress1() + joinUser.getExtraAddress();
		user.setAddress1(address1);
		user.setAddress2(joinUser.getAddress2());
		
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
		
		rttr.addFlashAttribute("msg", "회원가입이 완료되었습니다.");
		return "redirect:/user/login";
	}
}

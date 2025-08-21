package com.busanbank.card.cardapply.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/card/apply")
public class CardApplyController {

	@Autowired
	private IUserDao userDao;

//	@GetMapping("/termsAgree")
//	public String contactInfo(@RequestParam("cardNo") long cardNo, HttpSession session, Model model) {
//
//		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
//
//		System.out.println("cardNo: " + cardNo);
//
//		if (memberNo == null) {
//			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
//			return "user/userLogin";
//		}
//
//		model.addAttribute("cardNo", cardNo);
//		return "cardapply/termsAgree";
//	}

	@GetMapping("/termsAgree")
	public String termsAgree(HttpSession session) {
		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
		if (memberNo == null) {
			return "user/userLogin";
		}
		return "cardapply/termsAgree";
	}

//	@GetMapping("/customer-info")
//	public String customerInfo(@RequestParam("cardNo") int cardNo, HttpSession session, Model model,
//			RedirectAttributes rttr) throws Exception {
//
//		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
//
//		if (memberNo == null) {
//			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
//			return "user/userLogin";
//		}
//
//		UserDto loginUser = userDao.findByMemberNo(memberNo);
//
//		String rrnTailEnc = AESUtil.decrypt(loginUser.getRrnTailEnc());
//		String rrnBack = loginUser.getRrnGender() + rrnTailEnc;
//
//		model.addAttribute("loginUser", loginUser);
//		model.addAttribute("rrnBack", rrnBack);
//		model.addAttribute("cardNo", cardNo);
//
//		return "cardapply/customerInfo";
//	}

	@GetMapping("/customer-info")
	public String customerInfo(HttpSession session) {
		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");

		if (memberNo == null) {
			return "user/userLogin";
		}

		// 모델에 아무 것도 담지 않고 단순히 뷰 반환
		return "cardapply/customerInfo";
	}

//	@GetMapping("/contactInfo")
//	public String contactInfo(@RequestParam("applicationNo") Integer applicationNo, Model model) {
//		model.addAttribute("applicationNo", applicationNo);
//		return "cardapply/contactInfo";
//	}
//
//	@GetMapping("/jobInfo")
//	public String jobInfo(@RequestParam("applicationNo") Integer applicationNo, Model model) {
//		model.addAttribute("applicationNo", applicationNo);
//		return "cardapply/jobInfo";
//	}
//
//	@GetMapping("/addressInfo")
//	public String addressInfo(@RequestParam("applicationNo") Integer applicationNo, Model model) {
//		model.addAttribute("applicationNo", applicationNo);
//		return "cardapply/addressInfo";
//	}
//	
//	@GetMapping("/cardOption")
//	public String cardOption(@RequestParam("applicationNo") Integer applicationNo, Model model) {
//		model.addAttribute("applicationNo", applicationNo);
//		return "cardapply/cardOption";
//	}
//
//	@GetMapping("/nextPage")
//	public String nextPage(@RequestParam("applicationNo") Integer applicationNo, Model model) {
//		model.addAttribute("applicationNo", applicationNo);
//		return "cardapply/nextPage";
//	}

	@GetMapping("/contactInfo")
	public String contactInfo() {
		return "cardapply/contactInfo";
	}

	@GetMapping("/jobInfo")
	public String jobInfo() {
		return "cardapply/jobInfo";
	}

	@GetMapping("/addressInfo")
	public String addressInfo() {
		return "cardapply/addressInfo";
	}

	@GetMapping("/cardOption")
	public String cardOption() {
		return "cardapply/cardOption";
	}

	@GetMapping("/nextPage")
	public String nextPage() {
		return "cardapply/nextPage";
	}

	// 계좌관리
	@GetMapping("/accounts")
	public String accounts(@RequestParam(value = "cardNo", required = false) Integer cardNo, HttpSession session,
			Model model, RedirectAttributes rttr) {
		// 필요하면 model.addAttribute("cardNo", cardNo);
		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
		if (memberNo == null) {
			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
			return "user/userLogin";
		}
		return "cardapply/accounts";
	}

	// 카드비밀번호
	@GetMapping("/cardPassword")
	public String cardPassword(@RequestParam(value = "cardNo", required = false) Integer cardNo, HttpSession session,
			Model model, RedirectAttributes rttr) {
		model.addAttribute("cardNo", cardNo == null ? "" : cardNo); // ✅ 추가
		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");
		if (memberNo == null) {
			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
			return "user/userLogin";
		}
		return "cardapply/cardPassword";
	}

}

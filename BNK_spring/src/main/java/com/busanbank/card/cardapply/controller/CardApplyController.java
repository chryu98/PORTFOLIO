package com.busanbank.card.cardapply.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.busanbank.card.card.dao.CardDao;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.PdfFilesDto;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/card/apply")
public class CardApplyController {

	@Autowired
	private IUserDao userDao;
	@Autowired
	private CardDao cardDao;
	@Autowired
	private ICardApplyDao applyDao;
	
	@GetMapping("/termsAgree")
	public String contactInfo(@RequestParam("cardNo") long cardNo,
							  Model model) {
		String cardType = cardDao.selectCardTypeById(cardNo);
		List<PdfFilesDto> pdfFiles;
		
		if(cardType.equals("신용")) {
			pdfFiles = applyDao.selectCreditPdfFiles();
		} else {
			pdfFiles = applyDao.selectCheckPdfFiles();			
		}
		
		model.addAttribute("pdfFiles", pdfFiles);		
		model.addAttribute("cardNo", cardNo);
		return "cardapply/termsAgree";
	}
	
	@GetMapping("/customer-info")
	public String customerInfo(@RequestParam("cardNo") int cardNo,
							   HttpSession session, Model model,
							   RedirectAttributes rttr) throws Exception {
		
		Integer memberNo = (Integer) session.getAttribute("loginMemberNo");		

		if(memberNo == null) {
			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
			return "user/userLogin";
		}
		
		UserDto loginUser = userDao.findByMemberNo(memberNo);
		
		String rrnTailEnc = AESUtil.decrypt(loginUser.getRrnTailEnc());
		String rrnBack = loginUser.getRrnGender() + rrnTailEnc;
		
		model.addAttribute("loginUser", loginUser);
		model.addAttribute("rrnBack", rrnBack);
		model.addAttribute("cardNo", cardNo);
		
		return "cardapply/customerInfo";
	}
	
	@GetMapping("/contactInfo")
	public String contactInfo(@RequestParam("applicationNo") Integer applicationNo,
							  Model model) {
		model.addAttribute("applicationNo", applicationNo);
		return "cardapply/contactInfo";
	}

	@GetMapping("/jobInfo")
	public String jobInfo(@RequestParam("applicationNo") Integer applicationNo,
			  			  Model model) {		
		model.addAttribute("applicationNo", applicationNo);
		return "cardapply/jobInfo";
	}

	@GetMapping("/addressInfo")
	public String addressInfo(@RequestParam("applicationNo") Integer applicationNo,
			Model model) {		
		model.addAttribute("applicationNo", applicationNo);
		return "cardapply/addressInfo";
	}
}

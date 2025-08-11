package com.busanbank.card.cardapply.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
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
	
	@GetMapping("/customer-info/{cardNo}")
	public String customerInfo(@PathVariable("cardNo") int cardNo,
							   HttpSession session, Model model,
							   RedirectAttributes rttr) throws Exception {
		
		Integer memberNo = (Integer) session.getAttribute("memberNo");		

		if(memberNo == null) {
			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
			return "user/userLogin";
		}
		
		UserDto loginUser = userDao.findByMemberNo(memberNo);
		
		String rrnTailEnc = AESUtil.decrypt(loginUser.getRrnTailEnc());
		String rrnBack = loginUser.getRrnGender() + rrnTailEnc;
		
		model.addAttribute("loginUser", loginUser);
		model.addAttribute("rrnBack", rrnBack);
		
		return "cardapply/CustomerInfo";
	}
}

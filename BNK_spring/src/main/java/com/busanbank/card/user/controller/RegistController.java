package com.busanbank.card.user.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.TermDto;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/user/regist")
public class RegistController {

	@Autowired
	private IUserDao userDao;
	
	@GetMapping("/selectMemberType")
	public String selectMemberType(HttpSession session, Model model,
			 					   RedirectAttributes rttr) {
		
		String username = (String) session.getAttribute("loginUsername");
		if(username != null) {
			rttr.addFlashAttribute("msg", "이미 로그인된 사용자입니다.");
			return "redirect:/";
		}
		
		return "user/selectMemberType";
	}

	@GetMapping("/terms")
	public String terms(Model model,
	                    HttpSession session,
	                    RedirectAttributes rttr) {

		String username = (String) session.getAttribute("loginUsername");
		if (username != null) {
			rttr.addFlashAttribute("message", "이미 로그인된 사용자입니다.");
			return "redirect:/";
		}
		
		String role = (String) session.getAttribute("role");
	    if (role == null) {
	        rttr.addFlashAttribute("message", "회원유형이 선택되지 않았습니다.");
	        return "redirect:/user/regist/selectMemberType";
	    }

		List<TermDto> terms = userDao.findAllTerms();
		for (TermDto term : terms) {
			term.setAgreeYn("N");
		}

		model.addAttribute("terms", terms);
		//model.addAttribute("role", role);
		return "user/terms";
	}
	
	@GetMapping("/userRegistForm")
	public String userRegistForm(HttpSession session, Model model, 
								 RedirectAttributes rttr) {
		String username = (String) session.getAttribute("loginUsername");
        if (username != null) {
            rttr.addFlashAttribute("message", "이미 로그인된 사용자입니다.");
            return "redirect:/";
        }
        
        String role = (String) session.getAttribute("role");
        if (role == null) {
            rttr.addFlashAttribute("message", "회원유형이 선택되지 않았습니다.");
            return "redirect:/user/regist/selectMemberType";
        }
        
		return "user/userRegistForm";
	}

}
	
	

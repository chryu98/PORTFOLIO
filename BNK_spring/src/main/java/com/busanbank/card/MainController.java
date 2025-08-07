package com.busanbank.card;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.session.AdminSession;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.service.SessionService;

import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor // final 필드 주입용
public class MainController {

	@Autowired
	private IUserDao userDao;
	@Autowired
	private SessionService sessionService;

	
	@Autowired
	private AdminSession adminSession;
	// 여기가 페이지 이동기능 모아놓은 컨트롤러입니다.

	@GetMapping("/")
	public String root(HttpSession session, Model model) {
		
		UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
		if(loginUser == null) {
			return "index";
		}
		return "index";	
	}

	@GetMapping("/admin")
	public String admin() {
		AdminDto admin = adminSession.getLoginUser();
        if (admin == null) {
            return "redirect:/admin/adminLoginForm";
        }
		
		return "redirect:/admin/adminLoginForm";
	}

	@GetMapping("/cardList")
    public String cardListPage(HttpSession session, Model model) {
		
		UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
		if(loginUser == null) {
			return "cardList";
		}
		return "cardList"; // 카드리스트
    }
	
	@GetMapping("/cards/detail")
	public String cardDetailPage(HttpSession session, Model model) {
		
		UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
		if(loginUser == null) {
			return "cardDetail";
		}
		return "cardDetail"; // 카드디테일
	}
	
	@GetMapping("/faq")
	public String faqPage(HttpSession session, Model model) {
		
		UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
		if(loginUser == null) {
			return "faq";
		}
		return "faq"; // faq
	}
	
	@GetMapping("/introduce")
	public String introducePage(HttpSession session, Model model) {
		
		UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
		if(loginUser == null) {
			return "introduce";
		}
		return "introduce"; // 은행소개
	}
	
	@GetMapping("/custom")
	public String customPage() {
		return "custom";
	}
	
	

}

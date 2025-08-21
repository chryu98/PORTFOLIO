package com.busanbank.card.user.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.busanbank.card.card.dto.CardDto;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.service.SessionService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;


@Controller
@RequestMapping("/user")
public class UserController {

	@Autowired
	private IUserDao userDao;
	@Autowired
	private SessionService sessionService;
//	@Autowired
//	private BCryptPasswordEncoder bCryptPasswordEncoder;
	
//	@GetMapping("/login")
//	public String login(HttpServletRequest request,
//						@RequestParam(name = "error", required = false) String error,
//						@RequestParam(name = "logout", required = false) String logout,
//	                    @RequestParam(name = "expired", required = false) String expired,
//						Model model) {
//		
//		//아이디, 비밀번호 확인
//		if(error != null) {
//			model.addAttribute("msg", "아이디 또는 비밀번호가 올바르지 않습니다.");
//		}
//		
//		//로그아웃 버튼 눌렀을 때
//		if(logout != null && expired == null) {
//			model.addAttribute("msg", "로그아웃 되었습니다.");
//		}
//		
//		//세션 만료
//		if (expired != null) {
//	        model.addAttribute("msg", "인증이 만료되어 로그아웃 되었습니다.");
//	    }
//		
//		//중복로그인 방지용
//		if(request.getAttribute("expired") != null) {
//			model.addAttribute("msg", "다른 위치에서 로그인되어 로그아웃 되었습니다.");
//		}
//		
//		return "user/userLogin";
//	}
	
	@GetMapping("/login")
	public String login() {
		return "user/userLogin";
	}
	
	@GetMapping("/mypage")
	public String mypage(HttpSession session, Model model) {
		
		UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
		if(loginUser == null) {
			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
			return "user/userLogin";
		}
		
		List<CardDto> cards = userDao.findMyCard();
		model.addAttribute("cards", cards);
		
        String username = (String) session.getAttribute("loginUsername");
        String role = (String) session.getAttribute("loginRole");

        System.out.println("========= User Info =========");
        //System.out.println("memberNo: " + memberNo);
        System.out.println("username: " + username);
        System.out.println("role: " + role);
        System.out.println("=============================");

		return "user/mypage";
	}
	
	@GetMapping("/editProfile")
	public String editProfile(HttpSession session, Model model) {
		
		UserDto loginUser = sessionService.prepareLoginUserAndSession(session, model);
		if(loginUser == null) {
			model.addAttribute("msg", "로그인이 필요한 서비스입니다.");
			return "user/userLogin";
		}
		
		return "user/editProfile";
	}
	
//	@PostMapping("/update")
//	public String update(UserDto user,
//						@RequestParam("extraAddress") String extraAddress,
//						HttpSession session, Model model,
//						RedirectAttributes rttr) {
//		
//		UserDto loginUser = userDao.findByUsername(user.getUsername());
//		
//		//로그인 사용자와 세션에 저장된 사용자가 같을 때
//		if(user.getUsername().equals(session.getAttribute("loginUsername"))) {
//			
//			//비밀번호 변경 여부 확인
//			if(user.getPassword() != null && !user.getPassword().isEmpty()) {
//				
//				//기존 비밀번호와 일치 여부 확인
//				if(bCryptPasswordEncoder.matches(user.getPassword(), loginUser.getPassword())) {
//					rttr.addFlashAttribute("msg", "기존 비밀번호와 동일합니다. 새로운 비밀번호를 입력해주세요.");
//					return "redirect:/user/editProfile";
//				}
//				//새 비밀번호 암호화 후 update
//				String encodedPassword = bCryptPasswordEncoder.encode(user.getPassword());
//				user.setPassword(encodedPassword);
//				
//			}
//			else {
//				//기존값 유지
//				user.setPassword(loginUser.getPassword());				
//			}
//			
//			//주소 처리
//			if (!extraAddress.trim().isEmpty()) {
//		        user.setAddress1(user.getAddress1() + extraAddress);
//		    }
//			else {
//		        user.setAddress1(user.getAddress1());
//		    }
//			
//			//DB 수정
//			userDao.updateMember(user);
//			System.out.println(user);
//		}
//		return "redirect:/user/mypage";
//	}
	
	
}

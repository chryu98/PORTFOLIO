package com.busanbank.card.admin.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.session.AdminSession;

@Controller
@RequestMapping("/admin")
public class AdminMainController {

	@Autowired
	private AdminSession adminSession;
	
	// 상품 목록 페이지
	@GetMapping("/CardList")
	public String adminCardList() {
		AdminDto admin = adminSession.getLoginUser();

		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		else {}
		return "admin/adminCardList";
	}

	// 관리자 로그인 페이지
	@GetMapping("/adminLoginForm")
	public String adminLoginForm() {
		return "admin/adminLoginForm";
	}

	// 검색어 관리 페이지
	@GetMapping("/Search")
	public String adminSearch() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		else {return "admin/adminSearch";}
		
	}

	// 검색어 관리 통계 페이지
	@GetMapping("/Statistics")
	public String adminStatistics() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		else {return "admin/adminStatistics";}
		
	}

	// 상품 인가 페이지
	@GetMapping("/Impression")
	public String adminImpression() {
		AdminDto admin = adminSession.getLoginUser();

		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		
		 if ("SUPER_ADMIN".equals(admin.getRole())) {
	            // 상위 관리자
	            return "admin/superAdminPermission";
	        } else {
	            // 하위 관리자
	        	return "admin/adminImpression";
	        }
	}

	// 관리자 스크래핑 페이지
	@GetMapping("/Scraping")
	public String adminScraping() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		else {return "admin/adminScraping";}
		
	}
	
	//
	@GetMapping("/Mainpage")
	public String Mainpage() {
		return "index";
	}

	// 어드민 고객 채팅 관리 페이지 (adminChat.jsp)
	@GetMapping("/chat")
	public String adminChatPage() {
	    AdminDto admin = adminSession.getLoginUser();
	    if (admin == null) {
	        return "redirect:/admin/adminLoginForm";
	    }
	    return "admin/adminChat";
	}
	
	
	// 상품 약관 관리 페이지
	@GetMapping("/productTerms")
	public String productTerms() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		return "admin/adminTerms";
	}
	
	// 상품약관의 카드별 약관 페이지
	@GetMapping("/cardTerms")
	public String cardTerms() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		return "admin/adminCardTerms";
	}
	
	
	// 고객 정보 관리
	@GetMapping("/userinfomanagement")
	public String userinfomanagement() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		return "admin/adminUserInfoManagement";
	}
	
	// 추천 상품 관리
	@GetMapping("/recommenproducts")
	public String recommentproducts() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		return "admin/adminRecommenProducts";
	}
	
	// 리뷰 및 상품 판매 현황 리포트
	@GetMapping("/reviewreport")
	public String reviewreport() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		return "admin/adminReviewReport";
	}
	

	
	// 이탈률 관리
	@GetMapping("/bouncerate")
	public String bouncerate() {
		AdminDto admin = adminSession.getLoginUser();
		if (admin == null) {
			// 로그인 안한 경우
			return "redirect:/admin/adminLoginForm";
		}
		return "admin/adminBounceRate";
	}
	

	
	//=========================================
	// 상위 관리자
	@GetMapping("/superAdminPermission")
	public String superAdminPermission() {
		return "admin/superAdminPermission";
	}

}

package com.busanbank.card.admin.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.dao.IAdminCardDao;
import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.service.AdminCardService;
import com.busanbank.card.admin.session.AdminSession;
import com.busanbank.card.card.dto.CardDto;

@RequestMapping("/admin/card")
@RestController
public class AdminCardController {

	@Autowired
	IAdminCardDao iAdminCardDao;

	@Autowired
	AdminCardService adminCardService;

	@Autowired
	private AdminSession adminSession;

	// 게시중인 상품
	@GetMapping("/getCardList")
	public List<CardDto> getAllCards() {
		List<CardDto> cards = iAdminCardDao.getCardList();
		return cards;
	}
	
	// 수정 기타 등등 상품
	@GetMapping("/getCardList2")
	public List<CardDto> getAllCards2() {
		List<CardDto> cards = iAdminCardDao.getCardList2();
		return cards;
	}

	@PostMapping("/editCard/{cardNo}")
	public String editCard(@PathVariable("cardNo") Long cardNo, @RequestBody CardDto cardDto) {
		// ✅ AdminSession에서 로그인 사용자 정보 가져오기
		AdminDto loginAdmin = adminSession.getLoginUser();
		// ✅ 로그인 관리자 ID 가져오기
		String adminId = loginAdmin.getUsername(); // 또는 getAdminId(), DTO에 맞게
		cardDto.setCardNo(cardNo); // 카드 번호 설정

		boolean result = adminCardService.insertCardTemp(cardDto, "수정", adminId);
		return result ? "success" : "fail";
	}

	@PostMapping("/deleteCard/{cardNo}")
	public String deleteCard(@PathVariable("cardNo") Long cardNo) {
		// ✅ AdminSession에서 로그인 사용자 정보 가져오기
		AdminDto loginAdmin = adminSession.getLoginUser();
		// ✅ 로그인 관리자 ID 가져오기
		String adminId = loginAdmin.getUsername(); // 또는 getAdminId(), DTO에 맞게
		boolean result = adminCardService.insertCardTemp2(cardNo, "삭제", adminId);
		return result ? "success" : "fail";
	}
}

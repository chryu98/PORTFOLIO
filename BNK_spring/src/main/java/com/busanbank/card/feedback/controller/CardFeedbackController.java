package com.busanbank.card.feedback.controller;

import com.busanbank.card.feedback.dto.*;
import com.busanbank.card.feedback.entity.CardFeedback;
import com.busanbank.card.feedback.service.CardFeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

@Controller
@RequiredArgsConstructor
public class CardFeedbackController {

	private final CardFeedbackService service;

	/** Flutter 모달 제출용 */
	@PostMapping("/api/feedback")
	@ResponseBody
	public ResponseEntity<FeedbackCreateResp> create(@RequestBody FeedbackCreateReq req) {
		return ResponseEntity.ok(service.create(req));
	}

	/** 관리자 대시보드 JSP */
	@GetMapping("/admin/feedback")
	public String dashboard(org.springframework.ui.Model model,
			@RequestParam(name = "top", defaultValue = "10") int top) {
		var summary = service.dashboard(top);
		model.addAttribute("summary", summary);
		model.addAttribute("top", top);
		return "admin/feedback/dashboard";
	}

	@GetMapping("/admin/feedback/summary.json")
	@ResponseBody
	public DashboardSummary dashboardJson(@RequestParam(name = "top", defaultValue = "10") int top) {
		return service.dashboard(top);
	}
	
	/*
	 * @GetMapping("/api/feedback/{id}")
	 * 
	 * @ResponseBody public CardFeedback getOne(@PathVariable Long id) { return
	 * repo.findById(id).orElseThrow(); }
	 */
}

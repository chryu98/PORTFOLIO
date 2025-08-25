package com.busanbank.card.admin.controller;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.busanbank.card.admin.service.CardApprovalService;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.cardapply.dto.ApplicationPersonDto;
import com.busanbank.card.cardapply.dto.CardApplicationDto;

@Controller
@RequestMapping("/admin/card-approval")
public class AdminCardApprovalController {

	private final ICardApplyDao cardApplyDao;
	private final CardApprovalService cardApprovalService;
	
	public AdminCardApprovalController(ICardApplyDao cardApplyDao,
									   CardApprovalService cardApprovalService) {
		this.cardApplyDao = cardApplyDao;
		this.cardApprovalService = cardApprovalService;
	}
	
	
	@GetMapping("")
	public String cardApproval() {
		
		return "admin/adminCardApproval";
	}
	
	// 신청 목록 조회
    @GetMapping("/get-list")
    @ResponseBody
    public Map<String, Object> getApplications() {
        List<CardApplicationDto> cards = cardApprovalService.getCardApplicationsWithRecommendation();

        List<ApplicationPersonDto> persons = cardApplyDao.findPersonForApplications(
                cards.stream().map(CardApplicationDto::getApplicationNo).toList()
        );

        Map<Integer, ApplicationPersonDto> personMap = persons.stream()
                .collect(Collectors.toMap(ApplicationPersonDto::getApplicationNo, Function.identity()));

        return Map.of(
                "cards", cards,
                "persons", personMap
        );
    }

	
	//상태 변경 (승인/반려)
	@PostMapping("/update-status/{applicationNo}")
	@ResponseBody
	public ResponseEntity<?> updateStatus(@PathVariable("applicationNo") Integer applicationNo,
										  @RequestBody Map<String, String> body) {
        String status = body.get("status");
        String reason = body.getOrDefault("reason", "");
        int updated = cardApplyDao.updateStatusWithReason(applicationNo, status, reason);
        
        if (updated > 0) {
            return ResponseEntity.ok(Map.of("success", true));
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                                 .body(Map.of("success", false, "message", "Application not found"));
        }
    }
}

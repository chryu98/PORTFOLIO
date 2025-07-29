package com.busanbank.card.admin.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.dto.PermissionDto;
import com.busanbank.card.admin.service.SuperAdminPermissionService;
import com.busanbank.card.admin.session.AdminSession;
import com.busanbank.card.card.dto.CardDto;

@RestController
@RequestMapping("/superadmin/permission")
public class SuperAdminPermissionController {

	@Autowired
	private SuperAdminPermissionService permissionService;

	@Autowired
	private AdminSession adminSession;

	@GetMapping("/list")
	public Map<String, Object> getPermissionList(
	    @RequestParam(name = "page", defaultValue = "1") int page,
	    @RequestParam(name = "size", defaultValue = "10") int size) {

	    System.out.println("요청 page: " + page);
	    if (page <= 0) page = 1;

	    int offset = (page - 1) * size;
	    System.out.println("계산된 offset: " + offset);

	    List<PermissionDto> content = permissionService.getPermissionListPaged(offset, size);
	    int totalElements = permissionService.getPermissionCount();
	    int totalPages = (int) Math.ceil((double) totalElements / size);

	    Map<String, Object> response = new HashMap<>();
	    response.put("content", content);
	    response.put("totalPages", totalPages);
	    response.put("totalElements", totalElements);
	    response.put("page", page);
	    response.put("size", size);
	    return response;
	}



	@GetMapping("/temp/{cardNo}")
	public Map<String, Object> getCardComparison(@PathVariable("cardNo") Long cardNo) {
		CardDto tempCard = permissionService.getCardTemp(cardNo);
		CardDto originalCard = permissionService.getCardOriginal(cardNo);

		if (tempCard == null) {
			throw new IllegalStateException("TEMP 카드 데이터가 없습니다.");
		}

		Map<String, Object> map = new HashMap<>();
		map.put("temp", tempCard);
		map.put("original", originalCard);
		return map;
	}

	// 승인
	@PostMapping("/approve")
	public Map<String, Object> approve(@RequestBody CardDto dto) {
		AdminDto loginAdmin = adminSession.getLoginUser();
		if (loginAdmin == null) {
			throw new IllegalStateException("로그인이 필요합니다.");
		}
		CardDto tempCard = permissionService.getCardTemp(dto.getCardNo());
		if (tempCard == null) {
			throw new IllegalStateException("카드 TEMP 데이터가 없습니다.");
		}
		boolean success = permissionService.approveCard(tempCard, loginAdmin.getUsername());
		return Map.of("success", success, "message", success ? "카드를 승인했습니다." : "승인 실패");
	}

	// 삭제
	@PostMapping("/reject")
	public Map<String, Object> reject(@RequestParam("cardNo") Long cardNo, @RequestParam("status") String status,
			@RequestParam("reason") String reason) {
		AdminDto loginAdmin = adminSession.getLoginUser();
		if (loginAdmin == null) {
			throw new IllegalStateException("로그인이 필요합니다.");
		}
		boolean success = permissionService.rejectCard(cardNo, status, reason, loginAdmin.getUsername());
		return Map.of("success", success, "message", success ? status + " 처리 완료" : "처리 실패");
	}

	@PostMapping("/delete")
	public Map<String, Object> delete(@RequestParam("cardNo") Long cardNo) {
		AdminDto loginAdmin = adminSession.getLoginUser();
		if (loginAdmin == null) {
			throw new IllegalStateException("로그인이 필요합니다.");
		}
		boolean success = permissionService.deleteCard(cardNo, loginAdmin.getUsername());
		return Map.of("success", success, "message", success ? "카드가 삭제되었습니다." : "삭제 실패");
	}

}

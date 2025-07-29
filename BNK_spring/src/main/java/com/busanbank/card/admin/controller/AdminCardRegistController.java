package com.busanbank.card.admin.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.service.AdminCardRegistService;
import com.busanbank.card.admin.session.AdminSession;
import com.busanbank.card.card.dto.CardDto;

@RequestMapping("/admin")
@RestController
public class AdminCardRegistController {

    @Autowired
    private AdminCardRegistService adminCardRegistService;

    @Autowired
    private AdminSession adminSession;

    @PostMapping("/cardRegist")
    public ResponseEntity<Map<String, Object>> registerCard(
            @RequestBody CardDto cardDto
    ) {
    	
        Map<String, Object> response = new HashMap<>();

        // ✅ AdminSession에서 로그인 사용자 정보 가져오기
        AdminDto loginAdmin = adminSession.getLoginUser();

        if (loginAdmin == null) {
            response.put("message", "로그인이 필요합니다.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }

        // ✅ 로그인 관리자 ID 가져오기
        String adminId = loginAdmin.getUsername(); // 또는 getAdminId(), DTO에 맞게

        // ✅ 서비스에 관리자 ID 넘기기
        boolean result = adminCardRegistService.insertCardTemp(cardDto, "등록", adminId);

        response.put("success", result);
        response.put("message", result
                ? "카드 등록 요청이 완료되었습니다. 승인 대기중입니다."
                : "카드 등록 요청에 실패했습니다.");

        return ResponseEntity
                .status(result ? HttpStatus.CREATED : HttpStatus.INTERNAL_SERVER_ERROR)
                .body(response);
    }
}



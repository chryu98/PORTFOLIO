package com.busanbank.card.admin.controller;

import java.util.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import com.busanbank.card.admin.dto.AdminDto;
import com.busanbank.card.admin.service.AdminService;
import com.busanbank.card.admin.session.AdminSession;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/admin")
public class AdminLoginController {

    @Autowired
    private AdminService adminService;

    @Autowired
    private AdminSession adminSession;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody AdminDto request, HttpSession session) {
        try {
            AdminDto admin = adminService.login(request.getUsername(), request.getPassword());
            adminSession.login(admin, session);
            session.setMaxInactiveInterval(20 * 60); // 20분

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", "로그인 성공");
            result.put("user", admin);

            return ResponseEntity
                    .ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(result);

        } catch (RuntimeException e) {
            
            
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(HttpSession session) {
        Map<String, Object> result = new HashMap<>();

        if (!adminSession.isLoggedIn()) {
            result.put("success", false);
            result.put("message", "이미 로그아웃 상태입니다.");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(result);
        }

        adminSession.logout(session);

        result.put("success", true);
        result.put("message", "로그아웃 되었습니다.");
        return ResponseEntity.ok(result);
    }
    
    @GetMapping("/info")
    public ResponseEntity<?> getAdminInfo(HttpSession session) {
        AdminDto admin = (AdminDto) session.getAttribute("adminLoginUser"); // ← ✅ 정확한 key

        if (admin == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                 .body(Map.of("message", "세션 없음"));
        }

        return ResponseEntity.ok(Map.of(
            "name", admin.getName(),          // Flutter에서 adminName에 표시됨
            "username", admin.getUsername()
        ));
    }



}

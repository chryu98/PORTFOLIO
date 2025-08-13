package com.busanbank.card.card.controller;

import com.busanbank.card.card.dto.CardBehaviorLogDto;
import com.busanbank.card.card.service.CardBehaviorLogService;

import jakarta.servlet.http.HttpServletRequest;

import java.util.Date;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/log")
public class CardBehaviorLogController {

    @Autowired
    private CardBehaviorLogService behaviorLogService;

    @PostMapping("/card-behavior")
    public ResponseEntity<Void> logBehavior(@RequestBody CardBehaviorLogDto dto,HttpServletRequest request) {
    	 // ✅ 가드: 비로그인/무효 memberNo 차단
        if (dto == null || dto.getMemberNo() == null || dto.getMemberNo() <= 0) {
            return ResponseEntity.noContent().build(); // 저장 안 함
        }
        // (선택) cardNo도 무효면 차단
        if (dto.getCardNo() == null || dto.getCardNo() <= 0) {
            return ResponseEntity.noContent().build();
        }

        dto.setBehaviorTime(new Date()); // 서버에서 설정
        dto.setIpAddress(request.getRemoteAddr()); // 서버에서 설정(프록시 쓰면 X-Forwarded-For 사용 권장)

        behaviorLogService.saveBehavior(dto);
        return ResponseEntity.noContent().build();
    }
}

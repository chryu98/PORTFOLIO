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
    	 dto.setBehaviorTime(new Date()); // 서버에서 설정
    	    dto.setIpAddress(request.getRemoteAddr()); // 서버에서 설정
    	    behaviorLogService.saveBehavior(dto);
    	    return ResponseEntity.ok().build();
    }
}

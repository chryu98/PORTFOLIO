package com.busanbank.card.feedback.controller;

import com.busanbank.card.feedback.dto.InsightSummary;
import com.busanbank.card.feedback.service.CardFeedbackInsightService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/feedback")
public class CardFeedbackInsightController {

    private final CardFeedbackInsightService service;

    /**
     * 예) /api/feedback/insights?days=30&limit=5&minScore=0.55
     * - days: 최근 N일만 집계 (기본 30일)
     * - limit: 각 리스트 상위 N개 (기본 5)
     * - minScore: sentiment_score 컷(예: 0.55 미만 제외), 기본 미적용
     */
    @GetMapping("/insights")
    public InsightSummary insights(
            @RequestParam(required = false) Integer days,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Double minScore
    ) {
        return service.insights(days, limit, minScore);
    }
}

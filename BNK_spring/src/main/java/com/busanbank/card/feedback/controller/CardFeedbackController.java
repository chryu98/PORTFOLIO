package com.busanbank.card.feedback.controller;

import com.busanbank.card.feedback.dto.DashboardSummary;
import com.busanbank.card.feedback.dto.FeedbackCreateReq;
import com.busanbank.card.feedback.dto.FeedbackCreateResp;
import com.busanbank.card.feedback.dto.InsightSummary;
import com.busanbank.card.feedback.entity.CardFeedback;
import com.busanbank.card.feedback.service.CardFeedbackInsightService;
import com.busanbank.card.feedback.service.CardFeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequiredArgsConstructor
public class CardFeedbackController {

    private final CardFeedbackService service;
    private final CardFeedbackInsightService insightService;

    /** Flutter 모달 제출용 */
    @PostMapping(
            value = "/api/feedback",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    @ResponseBody
    public ResponseEntity<FeedbackCreateResp> create(@RequestBody FeedbackCreateReq req) {
        return ResponseEntity.ok(service.create(req));
    }

 // com/busanbank/card/feedback/controller/CardFeedbackController.java
    @GetMapping("/admin/feedback")
    public String dashboard(
            Model model,
            @RequestParam(name = "top",  defaultValue = "10") int top,
            @RequestParam(name = "days", defaultValue = "30") int days,
            @RequestParam(name = "minScore", required = false) Double minScore
    ) {
        var summary  = service.dashboard(top);
        var insights = insightService.insights(days, top, minScore); // ✅ 폴백/완화 로직 포함

        model.addAttribute("summary", summary);
        model.addAttribute("insights", insights);
        model.addAttribute("top", top);
        model.addAttribute("days", days);
        model.addAttribute("minScore", minScore);
        return "admin/feedback/dashboard";
    }


    /** 요약 JSON */
    @GetMapping(value = "/admin/feedback/summary.json", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseBody
    public DashboardSummary dashboardJson(@RequestParam(name = "top", defaultValue = "10") int top) {
        return service.dashboard(top);
    }

    /** 인사이트 JSON (필터 반영) */
    @GetMapping(value = "/admin/feedback/insights.json", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseBody
    public InsightSummary insightsJson(
            @RequestParam(name = "days",  defaultValue = "30") int days,
            @RequestParam(name = "limit", defaultValue = "10") int limit,
            @RequestParam(name = "minScore", required = false) Double minScore
    ) {
        return insightService.insights(days, limit, minScore);
    }

    /** 단건 조회 */
    @GetMapping(value = "/api/feedback/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseBody
    public CardFeedback getOne(@PathVariable("id") Long id) {
        return service.getOne(id);
    }
}

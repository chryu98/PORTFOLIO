package com.busanbank.card.admin.controller;

import com.busanbank.card.admin.service.AdminReviewReportService;
import com.busanbank.card.admin.dto.*;
import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor;
import java.util.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/api/review-report")
public class AdminReviewReportController {

    private final AdminReviewReportService service;

    @GetMapping("/summary")
    public Map<String, Object> summary(
        @RequestParam("startDt") String startDt,
        @RequestParam("endDt")   String endDt) {
        return service.summary(startDt, endDt);
    }

    // /trends 제거

    @GetMapping("/products")
    public List<ProductRow> products(
        @RequestParam("startDt") String startDt,
        @RequestParam("endDt")   String endDt) {
        return service.products(startDt, endDt);
    }

    // /breakdowns 제거

    @GetMapping("/demography")
    public Map<String, Object> demography(
        @RequestParam("startDt") String startDt,
        @RequestParam("endDt")   String endDt) {
        return service.demography(startDt, endDt);
    }

    @GetMapping("/combined")
    public List<CardCombinedRow> combined(
        @RequestParam("startDt") String startDt,
        @RequestParam("endDt")   String endDt) {
        return service.combined(startDt, endDt);
    }

    @GetMapping("/cards/demography")
    public List<CardDemogRow> cardsDemography(
        @RequestParam("startDt") String startDt,
        @RequestParam("endDt")   String endDt) {
        return service.cardsDemography(startDt, endDt);
    }
}

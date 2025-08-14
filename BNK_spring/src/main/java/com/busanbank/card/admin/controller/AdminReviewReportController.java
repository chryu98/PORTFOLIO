// src/main/java/com/busanbank/card/admin/controller/AdminReviewReportController.java
package com.busanbank.card.admin.controller;

import java.util.Date;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.dto.FunnelSummary;
import com.busanbank.card.admin.dto.OverviewKpi;
import com.busanbank.card.admin.dto.ProductDemographic;
import com.busanbank.card.admin.dto.ProductSummary;
import com.busanbank.card.admin.dto.SalesTrendPoint;
import com.busanbank.card.admin.service.AdminReviewReportService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/admin/report")
@RequiredArgsConstructor
public class AdminReviewReportController {

    private final AdminReviewReportService service;

    // 1) KPI
    @GetMapping("/overview")
    public OverviewKpi getOverview(
            @RequestParam("from") @DateTimeFormat(pattern = "yyyy-MM-dd") Date from,
            @RequestParam("to")   @DateTimeFormat(pattern = "yyyy-MM-dd") Date to) {
        return service.getOverview(from, to);
    }

    // 2) 판매 추세 (일별 ISSUED)
    @GetMapping("/sales-trend")
    public List<SalesTrendPoint> getSalesTrend(
            @RequestParam("from") @DateTimeFormat(pattern = "yyyy-MM-dd") Date from,
            @RequestParam("to")   @DateTimeFormat(pattern = "yyyy-MM-dd") Date to) {
        return service.getSalesTrend(from, to);
    }

    // 3) 상품별 판매 Top-N
    @GetMapping("/sales-by-product")
    public List<ProductSummary> getSalesByProduct(
            @RequestParam("from") @DateTimeFormat(pattern = "yyyy-MM-dd") Date from,
            @RequestParam("to")   @DateTimeFormat(pattern = "yyyy-MM-dd") Date to,
            @RequestParam(name = "top", required = false, defaultValue = "10") Integer top) {
        return service.getSalesByProduct(from, to, top);
    }

    // 4) 퍼널 요약
    @GetMapping("/funnel")
    public FunnelSummary getFunnel(
            @RequestParam("from") @DateTimeFormat(pattern = "yyyy-MM-dd") Date from,
            @RequestParam("to")   @DateTimeFormat(pattern = "yyyy-MM-dd") Date to) {
        return service.getFunnel(from, to);
    }

    // 5) 인구통계 (성별/연령)
    @GetMapping("/demographics")
    public List<ProductDemographic> getDemographics(
            @RequestParam("from") @DateTimeFormat(pattern = "yyyy-MM-dd") Date from,
            @RequestParam("to")   @DateTimeFormat(pattern = "yyyy-MM-dd") Date to) {
        return service.getProductDemographics(from, to);
    }
}

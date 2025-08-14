// src/main/java/com/busanbank/card/admin/service/AdminReviewReportService.java
package com.busanbank.card.admin.service;

import java.util.Date;
import java.util.List;

import org.springframework.stereotype.Service;

import com.busanbank.card.admin.dto.*;
import com.busanbank.card.admin.dao.AdminReviewReportMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AdminReviewReportService {

    private final AdminReviewReportMapper mapper;

    public OverviewKpi getOverview(Date from, Date to) {
        return mapper.selectOverview(from, to);
    }

    public List<SalesTrendPoint> getSalesTrend(Date from, Date to) {
        return mapper.selectSalesTrend(from, to);
    }

    public List<ProductSummary> getSalesByProduct(Date from, Date to, Integer top) {
        return mapper.selectSalesByProduct(from, to, top);
    }

    public FunnelSummary getFunnel(Date from, Date to) {
        return mapper.selectFunnel(from, to);
    }

    public List<ProductDemographic> getProductDemographics(Date from, Date to) {
        return mapper.selectProductDemographics(from, to);
    }
}

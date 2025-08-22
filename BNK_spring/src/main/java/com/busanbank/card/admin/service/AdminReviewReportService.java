package com.busanbank.card.admin.service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.busanbank.card.admin.dao.AdminReviewReportMapper;
import com.busanbank.card.admin.dto.KpiDto;
import com.busanbank.card.admin.dto.StatDto;
import com.busanbank.card.admin.dto.DemogRow;

@Service
public class AdminReviewReportService {

    @Autowired
    private AdminReviewReportMapper mapper;

    private void guardRange(String startDt, String endDt) {
        LocalDate s = LocalDate.parse(startDt);
        LocalDate e = LocalDate.parse(endDt);
        long days = ChronoUnit.DAYS.between(s, e) + 1; // 양끝 포함
        if (days <= 0) throw new IllegalArgumentException("기간이 올바르지 않습니다.");
        if (days > 31)  throw new IllegalArgumentException("조회 기간은 최대 31일까지 허용됩니다.");
    }

    public KpiDto kpi(String startDt, String endDt) {
        guardRange(startDt, endDt);

        int newApps = mapper.countNewApps(startDt, endDt);
        int issuedApps = mapper.countIssuedApps(startDt, endDt);
        int inProgress = mapper.countInProgressNow();

        Map<String,Object> cohort = mapper.cohortConversion(startDt, endDt);
        int cohortSize = ((Number)cohort.getOrDefault("COHORTSIZE",0)).intValue();
        int cohortIssued = ((Number)cohort.getOrDefault("COHORTISSUED",0)).intValue();

        Double avgIssueDays = mapper.avgIssueDays(startDt, endDt);
        double avgDays = (avgIssueDays == null) ? 0.0 : Math.round(avgIssueDays*10.0)/10.0;
        double convPct = cohortSize==0 ? 0.0 : Math.round(cohortIssued*1000.0/cohortSize)/10.0;

        KpiDto dto = new KpiDto();
        dto.setNewApps(newApps);
        dto.setIssuedApps(issuedApps);
        dto.setInProgress(inProgress);
        dto.setCohortSize(cohortSize);
        dto.setCohortIssued(cohortIssued);
        dto.setCohortConversionPct(convPct);
        dto.setAvgIssueDays(avgDays);
        return dto;
    }

    public Map<String, List<StatDto>> trends(String startDt, String endDt) {
        guardRange(startDt, endDt);
        Map<String, List<StatDto>> res = new HashMap<>();
        res.put("newApps", mapper.dailyNewApps(startDt, endDt));
        res.put("issued",  mapper.dailyIssued(startDt, endDt));
        return res;
    }

    /** 카드명/이미지 포함(조인) */
    public List<StatDto> productStats(String startDt, String endDt) {
        guardRange(startDt, endDt);
        return mapper.productStats(startDt, endDt);
    }

    /** 플래그 제거 → creditKind만 반환 */
    public Map<String, List<StatDto>> breakdowns(String startDt, String endDt) {
        guardRange(startDt, endDt);
        Map<String, List<StatDto>> res = new HashMap<>();
        res.put("creditKind", mapper.creditKindStats(startDt, endDt));
        return res;
    }

    /** 인구통계 */
    public Map<String, List<DemogRow>> demography(String startDt, String endDt) {
        guardRange(startDt, endDt);
        Map<String, List<DemogRow>> res = new HashMap<>();
        res.put("starts", mapper.demogStarts(startDt, endDt));
        res.put("issued", mapper.demogIssued(startDt, endDt));
        return res;
    }
}

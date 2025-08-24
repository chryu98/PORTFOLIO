package com.busanbank.card.admin.service;

import com.busanbank.card.admin.dao.AdminReviewReportMapper;
import com.busanbank.card.admin.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class AdminReviewReportService {

    private final AdminReviewReportMapper mapper;

    public Map<String,Object> summary(String startDt, String endDt) {
        int inflow      = mapper.countNewApps(Map.of("startDt", startDt, "endDt", endDt));
        int confirmed   = mapper.countIssuedApps(Map.of("startDt", startDt, "endDt", endDt)); // SIGNED
        int tempOpen    = mapper.countInProgressNow();

        Map<String, Object> cohort = mapper.cohortConversion(Map.of("startDt", startDt, "endDt", endDt));
        int cohortSize   = ((Number)cohort.getOrDefault("cohortSize", 0)).intValue();
        int cohortIssued = ((Number)cohort.getOrDefault("cohortIssued",0)).intValue();
        double cohortPct = cohortSize == 0 ? 0 : Math.round((cohortIssued*1000.0)/cohortSize)/10.0;

        Map<String,Object> res = new HashMap<>();
        res.put("tempInflow", inflow);
        res.put("finalConfirmed", confirmed);
        res.put("tempOpen", tempOpen);
        res.put("cohortConversionPct", cohortPct);
        return res;
    }

    // trends 제거

    public List<ProductRow> products(String startDt, String endDt) {
        return mapper.productStats(Map.of("startDt", startDt, "endDt", endDt));
    }

    // breakdowns 제거

    public Map<String,Object> demography(String startDt, String endDt) {
        List<DemogRow> starts = mapper.demogStarts(Map.of("startDt", startDt, "endDt", endDt));
        List<DemogRow> issued = mapper.demogIssued(Map.of("startDt", startDt, "endDt", endDt)); // SIGNED
        return Map.of("starts", starts, "issued", issued);
    }

    public List<CardCombinedRow> combined(String startDt, String endDt) {
        return mapper.cardCombined(Map.of("startDt", startDt, "endDt", endDt));
    }

    public List<CardDemogRow> cardsDemography(String startDt, String endDt) {
        return mapper.cardDemogMatrix(Map.of("startDt", startDt, "endDt", endDt));
    }
}

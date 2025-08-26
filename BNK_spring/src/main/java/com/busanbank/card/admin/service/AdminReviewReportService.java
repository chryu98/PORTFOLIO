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
        int inflow    = mapper.countNewApps(Map.of("startDt", startDt, "endDt", endDt));  // TEMP
        int confirmed = mapper.countIssuedApps(Map.of("startDt", startDt, "endDt", endDt)); // APPLICATION
        int tempOpen  = mapper.countInProgressNow();

        double convPct = inflow == 0 ? 0 : Math.round((confirmed * 1000.0) / inflow) / 10.0; // 소수1자리

        Map<String,Object> res = new HashMap<>();
        res.put("tempInflow", inflow);
        res.put("finalConfirmed", confirmed);
        res.put("tempOpen", tempOpen);
        // 프런트가 이 키를 쓰고 있으니 이름 유지
        res.put("cohortConversionPct", convPct);
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

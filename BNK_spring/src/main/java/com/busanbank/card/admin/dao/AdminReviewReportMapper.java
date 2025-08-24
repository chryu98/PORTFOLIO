package com.busanbank.card.admin.dao;

import com.busanbank.card.admin.dto.*;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;
import java.util.Map;

@Mapper
public interface AdminReviewReportMapper {

    // summary
    int countNewApps(Map<String,Object> p);
    int countIssuedApps(Map<String,Object> p); // SIGNED
    int countInProgressNow();
    Map<String,Object> cohortConversion(Map<String,Object> p);
    Double avgIssueDays(Map<String,Object> p); // 안 쓰면 남겨두거나 삭제

    // trends 삭제

    // products
    List<ProductRow> productStats(Map<String,Object> p);

    // breakdowns 삭제

    // demography
    List<DemogRow> demogStarts(Map<String,Object> p);
    List<DemogRow> demogIssued(Map<String,Object> p); // SIGNED

    // combined (card summary)
    List<CardCombinedRow> cardCombined(Map<String,Object> p);

    // card × demography matrix (자세히)
    List<CardDemogRow> cardDemogMatrix(Map<String,Object> p);
}

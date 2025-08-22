package com.busanbank.card.admin.dao;

import java.util.List;
import java.util.Map;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.admin.dto.StatDto;
import com.busanbank.card.admin.dto.DemogRow;

@Mapper
public interface AdminReviewReportMapper {
    // KPI
    int countNewApps(@Param("startDt") String startDt, @Param("endDt") String endDt);
    int countIssuedApps(@Param("startDt") String startDt, @Param("endDt") String endDt);
    int countInProgressNow();
    Map<String,Object> cohortConversion(@Param("startDt") String startDt, @Param("endDt") String endDt);
    Double avgIssueDays(@Param("startDt") String startDt, @Param("endDt") String endDt);

    // 트렌드
    List<StatDto> dailyNewApps(@Param("startDt") String startDt, @Param("endDt") String endDt);
    List<StatDto> dailyIssued(@Param("startDt") String startDt, @Param("endDt") String endDt);

    // 상품/세그
    List<StatDto> productStats(@Param("startDt") String startDt, @Param("endDt") String endDt);
    List<StatDto> creditKindStats(@Param("startDt") String startDt, @Param("endDt") String endDt);

    // 인구통계
    List<DemogRow> demogStarts(@Param("startDt") String startDt, @Param("endDt") String endDt);
    List<DemogRow> demogIssued(@Param("startDt") String startDt, @Param("endDt") String endDt);
}

// src/main/java/com/busanbank/card/admin/mapper/AdminReviewReportMapper.java
package com.busanbank.card.admin.dao;

import java.util.Date;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.admin.dto.*;

@Mapper
public interface AdminReviewReportMapper {

    OverviewKpi selectOverview(@Param("from") Date from, @Param("to") Date to);

    List<SalesTrendPoint> selectSalesTrend(@Param("from") Date from, @Param("to") Date to);

    List<ProductSummary> selectSalesByProduct(@Param("from") Date from, @Param("to") Date to, @Param("top") Integer top);

    FunnelSummary selectFunnel(@Param("from") Date from, @Param("to") Date to);

    List<ProductDemographic> selectProductDemographics(@Param("from") Date from, @Param("to") Date to);
}

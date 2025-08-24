package com.busanbank.card.custom.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface BenefitMapper {

  int exists(@Param("customNo") Long customNo);

  String getBenefit(@Param("customNo") Long customNo);

  int updateBenefit(@Param("customNo") Long customNo,
                    @Param("customService") String customService);

  int touch(@Param("customNo") Long customNo);
}

package com.busanbank.card.custom.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.custom.dto.CustomCardDto;

@Mapper
public interface CustomCardMapper {

  /** 시퀀스 다음 값 가져오기 */
  Long nextId();

  /** 커스텀 카드 등록 */
  void insert(CustomCardDto dto);

  /** 단건 조회 (customNo 기준) */
  CustomCardDto findById(@Param("customNo") Long customNo);
  
  int updateAi(@Param("customNo") Long customNo,
          @Param("aiResult") String aiResult,
          @Param("aiReason") String aiReason);
}

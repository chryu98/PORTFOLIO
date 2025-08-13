package com.busanbank.card.admin.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.admin.dto.CardInsightDto;

@Mapper
public interface RecoMapper {
    List<CardInsightDto> selectPopular(@Param("days") int days, @Param("limit") int limit);

    List<CardInsightDto> selectSimilar(@Param("cardNo") long cardNo,
                                       @Param("days") int days,
                                       @Param("limit") int limit);

    List<CardInsightDto> selectKpi(@Param("days") int days);

    List<CardInsightDto> selectLogs(@Param("memberNo") Long memberNo,
                                    @Param("cardNo")   Long cardNo,
                                    @Param("type")     String type,
                                    @Param("from")     String from,
                                    @Param("to")       String to,
                                    @Param("offset")   int offset,
                                    @Param("pageSize") int pageSize);

    // ★ 추가: 이름으로 가장 적합한 카드번호 1개 찾기
    Long findTopCardNoByName(@Param("name") String name,
                             @Param("days") Integer days);
}

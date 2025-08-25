package com.busanbank.card.admin.dao;

import com.busanbank.card.admin.dto.CardInsightDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

//com.busanbank.card.admin.dao.RecoMapper
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

 Long findTopCardNoByName(@Param("name") String name, @Param("days") Integer days);

 // ★ 자동완성용(현재 JSP가 호출함)
 List<CardInsightDto> searchCards(@Param("q") String q);
 List<CardInsightDto> searchMembers(@Param("q") String q);
 
 
 // 앱에서의 추가
 void insertBehaviorLog(@Param("memberNo") Long memberNo,
         @Param("cardNo") Long cardNo,
         @Param("type") String type,
         @Param("isoTime") String isoTime,
         @Param("device") String device,
         @Param("ua") String ua,
         @Param("ip") String ip);
 
}

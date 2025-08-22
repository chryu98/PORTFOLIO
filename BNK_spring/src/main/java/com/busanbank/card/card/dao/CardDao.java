package com.busanbank.card.card.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.card.dto.CardDto;

@Mapper // 스캔만 하면 xml과 자동 매핑
public interface CardDao {
	List<CardDto> selectAll(); // 카드 전체 조회
	
    CardDto selectById(@Param("cardNo") long cardNo); // 카드 1건 조회 (필요 시)

    String selectCardTypeById(@Param("cardNo") long cardNo);

    int updateViewCount(@Param("cardNo") long cardNo);  // 조회수  (예시)
    
    List<CardDto> searchByKeyword(
    	    @Param("keyword") String keyword,
    	    @Param("type") String type,
    	    @Param("tags") List<String> tags
    	); //카드 리스트 정렬(?)
    
    List<CardDto> selectPopularCards();
    
    List<CardDto> selectTop3ByView();
}

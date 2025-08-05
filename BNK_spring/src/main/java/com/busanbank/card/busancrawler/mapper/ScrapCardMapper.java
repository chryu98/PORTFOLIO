package com.busanbank.card.busancrawler.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.busancrawler.dto.ScrapCardDto;

@Mapper
public interface ScrapCardMapper {
	public void insertCard(ScrapCardDto card); //리스트 삽입
	
	public List<ScrapCardDto> getScrapList(); //리스트 조회
	
	int deleteAllCards(); // 전체 삭제
	
	ScrapCardDto getCardById(Long scCardNo);
	
}

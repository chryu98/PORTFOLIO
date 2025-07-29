package com.busanbank.card.admin.dao;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.admin.dto.SearchLogDto;

@Mapper
public interface IAdminSearchDao {
	
	// 검색어 로그 테이블 저장
	void insertSearchLog(SearchLogDto dto);
	
	// 금칙어 여부
	int isProhibitedKeyword(String keyword);
	// 추천어 여부
	int isRecommendedKeyword(String keyword);

	List<Map<String, Object>> getSearchLogsByPeriod(Map<String, Object> param);
	int getSearchLogsCount(Map<String, Object> param);

	// 조회
    List<Map<String, Object>> getRecommendedWords();	// 추천어 조회
    List<Map<String, Object>> getProhibitedWords();		// 금칙어 조회
    List<Map<String, Object>> getTopKeywords();			// 인기 검색어 조회
    List<Map<String, Object>> getRecentSearchLogs();	// 최근 검색어 30개
    
    // 추천어
    void insertRecommended(Map<String, Object> param);	// 추천어 등록
    void updateRecommended(Map<String, Object> param);	// 추천어 수정
    void deleteRecommended(Long id);					// 추천어 삭제

    // 금칙어
    void insertProhibited(Map<String, Object> param);	// 금칙어 등록
    void updateProhibited(Map<String, Object> param);	// 금칙어 수정
    void deleteProhibited(Long id);						// 금칙어 삭제
    

	
}

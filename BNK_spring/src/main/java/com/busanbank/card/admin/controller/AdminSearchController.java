package com.busanbank.card.admin.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.dao.IAdminSearchDao;
import com.busanbank.card.admin.dto.SearchLogDto;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/admin/Search")
public class AdminSearchController {

	@Autowired
	private IAdminSearchDao adminSearchDao;

	// cardList.jsp
	// 검색어 로그 테이블 저장
	@PostMapping("/searchlog")
	public void insertSearchLog(
	        @RequestBody SearchLogDto dto,
	        HttpSession session) {
		
		if (dto.getKeyword() == null || dto.getKeyword().trim().isEmpty()) {
	        // 그냥 아무 동작도 안함 (또는 로그만 찍기)
	        return;
	    }
		
		
		
	    // 세션에서 회원번호 꺼내기
		   Object memberNoObj = session.getAttribute("loginMemberNo");
		    if (memberNoObj != null) {
		        Long memberNo = ((Number) memberNoObj).longValue();
		        dto.setMemberNo(memberNo);
		    } else {
		        dto.setMemberNo(null); // 비회원은 null 처리
		    }

	    // 금칙어/추천어 여부 체크
	    boolean isProhibited = adminSearchDao.isProhibitedKeyword(dto.getKeyword()) > 0;
	    boolean isRecommended = adminSearchDao.isRecommendedKeyword(dto.getKeyword()) > 0;

	    dto.setIsProhibited(isProhibited ? "Y" : "N");
	    dto.setIsRecommended(isRecommended ? "Y" : "N");

	    // 저장
	    adminSearchDao.insertSearchLog(dto);
	}
	
	// 기간별 검색 로그 조회
	@GetMapping("/logs")
	public Map<String, Object> getSearchLogsByPeriod(
	    @RequestParam(value = "from", required = false) String from,
	    @RequestParam(value = "to", required = false) String to,
	    @RequestParam(value = "page", defaultValue = "1") int page,
	    @RequestParam(value = "size", defaultValue = "20") int size)
 {

	    // 계산
	    int offset = (page - 1) * size;

	    // 파라미터 맵
	    Map<String, Object> param = new HashMap<>();
	    param.put("from", from);
	    param.put("to", to);
	    param.put("offset", offset);
	    param.put("limit", size);

	    // 데이터 조회
	    List<Map<String, Object>> data = adminSearchDao.getSearchLogsByPeriod(param);

	    // 총 개수 조회
	    int totalCount = adminSearchDao.getSearchLogsCount(param);

	    // 결과 맵
	    Map<String, Object> result = new HashMap<>();
	    result.put("page", page);
	    result.put("totalPages", (int) Math.ceil((double) totalCount / size));
	    result.put("data", data);

	    return result;
	}






	// 추천어 목록
	@GetMapping("/recommended")
	public List<Map<String, Object>> getRecommendedWords() {
		return adminSearchDao.getRecommendedWords();
	}

	// 금칙어 목록
	@GetMapping("/prohibited")
	public List<Map<String, Object>> getProhibitedWords() {
		return adminSearchDao.getProhibitedWords();
	}

	// 인기 검색어 TOP10
	@GetMapping("/top")
	public List<Map<String, Object>> getTopKeywords() {
		return adminSearchDao.getTopKeywords();
	}



	// ========== 추천어 CRUD ==========
	// 추천어 등록
	@PostMapping("/recommended")
	public void insertRecommended(@RequestBody Map<String, Object> param) {
		adminSearchDao.insertRecommended(param);
	}

	// 추천어 수정
	@PutMapping("/recommended/{id}")
	public void updateRecommended(@PathVariable("id") Long id, @RequestBody Map<String, Object> param) {
		param.put("id", id);
		adminSearchDao.updateRecommended(param);
	}

	// 추천어 삭제
	@DeleteMapping("/recommended/{id}")
	public void deleteRecommended(@PathVariable("id") Long id) {
		adminSearchDao.deleteRecommended(id);
	}

	// ========== 금칙어 CRUD ==========

	// 금칙어 등록
	@PostMapping("/prohibited")
	public void insertProhibited(@RequestBody Map<String, Object> param) {
		adminSearchDao.insertProhibited(param);
	}

	// 금칙어 수정
	@PutMapping("/prohibited/{id}")
	public void updateProhibited(@PathVariable("id") Long id, @RequestBody Map<String, Object> param) {
		param.put("id", id);
		adminSearchDao.updateProhibited(param);
	}

	// 금칙어 삭제
	@DeleteMapping("/prohibited/{id}")
	public void deleteProhibited(@PathVariable("id") Long id) {
		adminSearchDao.deleteProhibited(id);
	}

}

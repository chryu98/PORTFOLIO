package com.busanbank.card.card.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.busanbank.card.admin.dao.IAdminSearchDao;
import com.busanbank.card.busancrawler.dto.ScrapCardDto;
import com.busanbank.card.busancrawler.mapper.ScrapCardMapper;
import com.busanbank.card.busancrawler.service.SeleniumCardCrawler;
import com.busanbank.card.card.dto.CardDto;
import com.busanbank.card.card.service.CardService;

import lombok.RequiredArgsConstructor;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class CardController {

	private final CardService cardService;
	private final IAdminSearchDao adminSearchDao;
	private final SeleniumCardCrawler seleniumCardCrawler;  // ✅ 추가
	private final ScrapCardMapper scrapCardMapper;  // ✅ 추가

	@Autowired
    private JdbcTemplate jdbcTemplate;

	
	@GetMapping("/cards")
	public List<CardDto> findAll() {
		return cardService.getCardList();
	}

	//비교하기
	@GetMapping("/cards/{cardNo}")
	public ResponseEntity<?> getCard(@PathVariable("cardNo") String cardNo) {
	    if (cardNo.startsWith("scrap_")) {
	        // scrap_ 접두어 제거하고 scCardNo로 파싱
	        long scCardNo = Long.parseLong(cardNo.replace("scrap_", ""));
	        ScrapCardDto match = scrapCardMapper.getCardById(scCardNo); // Mapper 메서드 필요
	        System.out.println("타행카드: "+scCardNo);
	        System.out.println(match);
	        if (match == null) {
	            return ResponseEntity.status(HttpStatus.NOT_FOUND)
	                                 .body("타행카드 정보를 찾을 수 없습니다.");
	        }

	        return ResponseEntity.ok(match);
	    } else {
	    	System.out.println("자행카드: "+cardNo);
	        Long realNo = Long.parseLong(cardNo);
	        return ResponseEntity.ok(cardService.getCard(realNo));
	    }
	}


	@GetMapping("/cards/search")
	public List<CardDto> searchCards(@RequestParam(value = "q", required = false) String q,
	                                 @RequestParam(value = "type", required = false) String type,
	                                 @RequestParam(value = "tags", required = false) String tags) {
	    if (q != null && adminSearchDao.isProhibitedKeyword(q) > 0) {
	        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "해당 단어는 검색할 수 없습니다");
	    }

	    if (type == null || type.isBlank()) {
	        if ("신용".equals(q)) {
	            type = "신용";
	            q = null;
	        } else if ("체크".equals(q)) {
	            type = "체크";
	            q = null;
	        }
	    }

	    List<String> tagList = (tags == null || tags.isBlank()) ? List.of() : List.of(tags.split(","));
	    return cardService.search(q, type, tagList);
	}

	@PutMapping("/cards/{cardNo}/view")
	public ResponseEntity<Void> increaseViewCount(@PathVariable("cardNo") int cardNo) {
	    cardService.increaseViewCount(cardNo);
	    return ResponseEntity.ok().build();  
	}

	// 타행카드 전체 목록 (공개용)
	@GetMapping("/public/cards/scrap")
	public List<ScrapCardDto> publicScrapCards() {
	    return seleniumCardCrawler.getScrapList();
	}
	
	@GetMapping("/cards/popular")
	public List<CardDto> getPopularCards() {
	    return cardService.getPopularCards();
	}
	
	
	// 추천어
	@GetMapping("/recommend/keywords")
    public List<String> getRecommendedKeywords() {
        String sql = "SELECT KEYWORD FROM RECOMMENDED_WORD ORDER BY REG_DATE DESC";
        return jdbcTemplate.query(sql, (rs, rowNum) -> rs.getString("KEYWORD"));
    }
	
	//플러터용 인기카드 3개
	@GetMapping("/cards/top3")
    public List<CardDto> popularTop3() {
		System.out.println(cardService.getPopularTop3());
        return cardService.getPopularTop3();
    }
	

}


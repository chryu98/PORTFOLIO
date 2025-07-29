package com.busanbank.card.busancrawler.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.busancrawler.dto.ScrapCardDto;
import com.busanbank.card.busancrawler.service.SeleniumCardCrawler;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/admin/card")
public class CrawlController {


	@Autowired
	SeleniumCardCrawler seleniumCardCrawler;

    @PostMapping("/scrap")
    public String scrapCards() {
        return seleniumCardCrawler.crawlShinhanCards(); // 크롤링 결과 로그 문자열 반환
    }
    
    @GetMapping("/getScrapList")
    public List<ScrapCardDto> getAllCards() {
		List<ScrapCardDto> cards = seleniumCardCrawler.getScrapList();
		return cards;
	}
	
    
    @DeleteMapping("/deleteAll")
    public String deleteAllCards() {
        int deletedCount = seleniumCardCrawler.deleteAllScrapCards();
        return deletedCount + "건 삭제 완료되었습니다.";
    }
    
    @GetMapping("/compare")
    public List<ScrapCardDto> getScrapedCards() {
        return seleniumCardCrawler.getScrapList();  // DB에서 타행 카드 리스트 조회
    }
}
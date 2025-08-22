package com.busanbank.card.card.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.busanbank.card.card.dao.CardDao;
import com.busanbank.card.card.dto.CardDto;

import lombok.RequiredArgsConstructor;

@Service               
@RequiredArgsConstructor 
public class CardService {

    private final CardDao cardDao;

    // 전체 카드 조회 
    public List<CardDto> getCardList() {
        return cardDao.selectAll();
    }

    //카드 1건 조회 (필요 시)
    public CardDto getCard(long cardNo) {
        return cardDao.selectById(cardNo);
    }

    // 조회수  (예시)
    public void increaseViewCount(long cardNo) {
        cardDao.updateViewCount(cardNo);
    }
    
    //카드리스트 검색기능 
    public List<CardDto> search(String keyword, String type, List<String> tags) {
        return cardDao.searchByKeyword(keyword, type, tags);
    }
    
    //상단 유명카드 이미지 불러오기
    public List<CardDto> getPopularCards() {
        return cardDao.selectPopularCards();
    }
    
    //플러터 메인페이지용 인기카드 3개
    public List<CardDto> getPopularTop3() {
        return cardDao.selectTop3ByView();
    }
    

}
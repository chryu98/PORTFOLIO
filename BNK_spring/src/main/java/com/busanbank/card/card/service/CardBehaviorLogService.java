package com.busanbank.card.card.service;

import com.busanbank.card.card.dao.CardBehaviorLogMapper;
import com.busanbank.card.card.dto.CardBehaviorLogDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CardBehaviorLogService {

    @Autowired
    private CardBehaviorLogMapper mapper;

    public void saveBehavior(CardBehaviorLogDto dto) {
    	 System.out.println(">>> Saving behavior log: " + dto);
        mapper.insertBehavior(dto);
    }
}

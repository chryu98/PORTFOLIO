package com.busanbank.card.card.dao;

import com.busanbank.card.card.dto.CardBehaviorLogDto;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface CardBehaviorLogMapper {
    void insertBehavior(CardBehaviorLogDto dto);
}

package com.busanbank.card.custom.mapper;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.custom.dto.CustomCardDto;

@Mapper
public interface CustomCardMapper {
  Long nextId();
  void insert(CustomCardDto dto);
}

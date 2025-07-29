package com.busanbank.card.admin.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.admin.dto.PermissionParamDto;
import com.busanbank.card.card.dto.CardDto;

@Mapper
public interface IAdminCardDao {
	
	// 게시중인 상품
	public List<CardDto> getCardList();
	// 수정중 기타 종류인 상품
	public List<CardDto> getCardList2();
	
	public int insertCardTemp(CardDto cardDto);
	
	public int insertPermission(PermissionParamDto perDto);
	//카드번호, 담당관리자

	
	CardDto selectCard(@Param("cardNo") Long cardNo);
	
}

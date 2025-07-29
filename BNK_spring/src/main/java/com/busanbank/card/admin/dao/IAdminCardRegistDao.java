package com.busanbank.card.admin.dao;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.admin.dto.PermissionParamDto;
import com.busanbank.card.card.dto.CardDto;

@Mapper
public interface IAdminCardRegistDao {

	public int insertCardTemp2(CardDto cardDto);

	public int insertPermission2(PermissionParamDto perDto);
	// 카드번호, 담당관리자

//	getNextCardSeq()는 카드 등록 시 CARD_NO를 새로 생성하기 위해 데이터베이스 시퀀스 
//	CARD_SEQ.NEXTVAL의 값을 조회하는 메서드입니다. 이렇게 조회한 카드번호를 card_temp와 
//	permission 테이블에 같이 저장해 두 테이블의 연관성을 유지합니다.

	public Long getNextCardSeq();
}

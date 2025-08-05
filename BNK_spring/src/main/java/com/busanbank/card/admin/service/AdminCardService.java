package com.busanbank.card.admin.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.busanbank.card.admin.dao.IAdminCardDao;
import com.busanbank.card.admin.dto.PermissionParamDto;
import com.busanbank.card.card.dto.CardDto;

@Service
public class AdminCardService {

	@Autowired
	IAdminCardDao adminCardDao;

	//수정,등록 용
	@Transactional
	public boolean insertCardTemp(CardDto cardDto, String s, String adminId) {
		PermissionParamDto perDto = new PermissionParamDto();
		perDto.setCardNo(cardDto.getCardNo());
		perDto.setPerContent(s);
		perDto.setAdmin(adminId);
		
		int updated1 = adminCardDao.insertCardTemp(cardDto);
		int updated2 = adminCardDao.insertPermission(perDto);
		
		return updated1 > 0 && updated2 > 0;
	}
	
	//삭제용
	@Transactional
	public boolean insertCardTemp2(Long cardNo, String perContent, String adminId) {
	    // 1. 원본 카드 정보 조회
	    CardDto originalCard = adminCardDao.selectCard(cardNo);
	    if (originalCard == null) {
	    	 System.out.println("❌ CARD에서 해당 카드 번호를 찾을 수 없습니다: " + cardNo);
	        return false; // 존재하지 않으면 실패
	    }

	    System.out.println("✅ CARD_TEMP에 저장할 카드 정보: " + originalCard);
	    int tempInserted = adminCardDao.insertCardTemp(originalCard);
	    System.out.println("insertCardTemp result: " + tempInserted);

	    // 3. PERMISSION 테이블에 삭제 요청 등록
	    PermissionParamDto perDto = new PermissionParamDto();
	    perDto.setCardNo(cardNo);
	    perDto.setPerContent(perContent);
	    perDto.setAdmin(adminId);
	    int permissionInserted = adminCardDao.insertPermission(perDto);

	    return tempInserted > 0 && permissionInserted > 0;
	}


}

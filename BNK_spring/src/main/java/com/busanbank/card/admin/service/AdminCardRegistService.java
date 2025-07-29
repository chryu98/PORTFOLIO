package com.busanbank.card.admin.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.busanbank.card.admin.dao.IAdminCardRegistDao;
import com.busanbank.card.admin.dto.PermissionParamDto;
import com.busanbank.card.card.dto.CardDto;

@Service
public class AdminCardRegistService {

    @Autowired
    IAdminCardRegistDao adminCardRegistDao;

    @Transactional
    public boolean insertCardTemp(CardDto cardDto, String perContent, String adminId) {
        Long cardNo = adminCardRegistDao.getNextCardSeq();
        cardDto.setCardNo(cardNo);

        PermissionParamDto perDto = new PermissionParamDto();
        perDto.setCardNo(cardDto.getCardNo());
        perDto.setPerContent(perContent);
        perDto.setAdmin(adminId);

        int updated1 = adminCardRegistDao.insertCardTemp2(cardDto);
        int updated2 = adminCardRegistDao.insertPermission2(perDto);

        return updated1 > 0 && updated2 > 0;
    }

}


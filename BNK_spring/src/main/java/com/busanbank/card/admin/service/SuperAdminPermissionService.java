package com.busanbank.card.admin.service;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.busanbank.card.admin.dao.ISuperAdminPermissionDao;
import com.busanbank.card.admin.dto.PermissionDto;
import com.busanbank.card.card.dto.CardDto;

@Service
public class SuperAdminPermissionService {

    @Autowired
    private ISuperAdminPermissionDao dao;

    public List<PermissionDto> getPermissionList() {
        return dao.selectPermissionList();
    }

    public CardDto getCardTemp(Long cardNo) {
        return dao.selectCardTemp(cardNo);
    }

    public CardDto getCardOriginal(Long cardNo) {
        return dao.selectCardOriginal(cardNo);
    }

    public boolean approveCard(CardDto dto, String sAdmin) {
        int inserted = dao.insertOrUpdateCard(dto);
        int updated = dao.updatePermissionApprove(dto.getCardNo(), sAdmin);
        return inserted > 0 && updated > 0;
    }

    public boolean rejectCard(Long cardNo, String status, String reason, String sAdmin) {
        if ("삭제".equals(status)) {
            return dao.updatePermissionCancel(cardNo, sAdmin) > 0;
        } else {
            return dao.updatePermissionReject(cardNo, status, reason, sAdmin) > 0;
        }
    }
    
    @Transactional
    public boolean deleteCard(Long cardNo, String sAdmin) {
        int deletedMain = dao.deleteCard(cardNo);
        int deletedTemp = dao.deleteCardTemp(cardNo);
        int updatedPermission = dao.updatePermissionCancel(cardNo, sAdmin);
        return deletedMain > 0 && updatedPermission > 0;
    }

    public List<PermissionDto> getPermissionListPaged(int offset, int size) {
    	System.out.println("SERVICE offset = " + offset + ", size = " + size);
        return dao.selectPermissionListPaged(offset, size);
    }

    public int getPermissionCount() {
        return dao.selectPermissionCount();
    }
}

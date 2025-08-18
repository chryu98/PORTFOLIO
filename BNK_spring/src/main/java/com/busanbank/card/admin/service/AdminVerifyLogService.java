package com.busanbank.card.admin.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.busanbank.card.admin.dao.IAdminVerifyLogDao;
import com.busanbank.card.admin.dto.VerifyLogDto;

@Service
public class AdminVerifyLogService {

    private final IAdminVerifyLogDao verifyLogDao;

    public AdminVerifyLogService(IAdminVerifyLogDao verifyLogDao) {
        this.verifyLogDao = verifyLogDao;
    }

    public List<VerifyLogDto> getAllLogs() {
        return verifyLogDao.findAll();
    }

    public List<VerifyLogDto> getLogsByUser(String userNo) {
        return verifyLogDao.findByUserNo(userNo);
    }

    public void saveLog(String userNo, String status, String reason) {
        VerifyLogDto log = new VerifyLogDto();
        log.setUserNo(userNo);
        log.setStatus(status);
        log.setReason(reason);
        verifyLogDao.insertLog(log);
    }
}

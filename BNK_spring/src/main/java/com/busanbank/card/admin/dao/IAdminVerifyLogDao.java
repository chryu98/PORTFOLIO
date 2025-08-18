package com.busanbank.card.admin.dao;

import java.util.List;
import com.busanbank.card.admin.dto.VerifyLogDto;

public interface IAdminVerifyLogDao {
    List<VerifyLogDto> findAll();
    List<VerifyLogDto> findByUserNo(String userNo);
    int insertLog(VerifyLogDto log);
}

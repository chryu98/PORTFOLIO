package com.busanbank.card.admin.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.busanbank.card.admin.dao.IAdminLoginDao;
import com.busanbank.card.admin.dto.AdminDto;

@Service
public class AdminService {

    @Autowired
    private IAdminLoginDao adminLoginDao;

    public AdminDto login(String username, String password) {
        AdminDto param = new AdminDto();
        param.setUsername(username);

        AdminDto admin = adminLoginDao.adminLogin(param);

        if (admin == null) {
            throw new RuntimeException("아이디 없음");
        }

        if (!admin.getPassword().equals(password)) {
            throw new RuntimeException("비밀번호 불일치");
        }

        return admin;
    }
}

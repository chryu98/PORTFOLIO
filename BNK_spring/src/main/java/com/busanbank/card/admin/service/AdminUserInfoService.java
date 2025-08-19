package com.busanbank.card.admin.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.busanbank.card.admin.dao.IAdminUserInfo;
import com.busanbank.card.admin.dto.ApplicationViewDto;
import com.busanbank.card.user.dto.UserDto;

@Service
public class AdminUserInfoService {

    @Autowired
    private IAdminUserInfo adminUserInfo;

    public List<UserDto> getAllUsers() {
        return adminUserInfo.findAllUsers();
    }
    
    // ★ 신규
    public List<ApplicationViewDto> getApplicationsByMember(Long memberNo) {
        return adminUserInfo.findApplicationsByMember(memberNo);
    }
}

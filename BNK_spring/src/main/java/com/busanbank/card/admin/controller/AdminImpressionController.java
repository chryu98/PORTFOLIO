package com.busanbank.card.admin.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.dao.IAdminPermissionDao;
import com.busanbank.card.admin.dto.PermissionDto;

@RestController
@RequestMapping("/admin")
public class AdminImpressionController {

    @Autowired
    private IAdminPermissionDao adminPermissionDao;

    // 인가 전체 조회
    @GetMapping("/permissions")
    public List<PermissionDto> listPermissions() {
        return adminPermissionDao.selectAllPermissions();
    }
}

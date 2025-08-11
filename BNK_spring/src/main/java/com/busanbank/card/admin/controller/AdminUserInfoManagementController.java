package com.busanbank.card.admin.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.admin.service.AdminUserInfoService;
import com.busanbank.card.user.dto.UserDto;

@RequestMapping("/admin")
@RestController
public class AdminUserInfoManagementController {

    @Autowired
    private AdminUserInfoService adminUserInfoService;

   
    @GetMapping("/user/list")
    public List<UserDto> getUserList() {
        return adminUserInfoService.getAllUsers();
    }
}

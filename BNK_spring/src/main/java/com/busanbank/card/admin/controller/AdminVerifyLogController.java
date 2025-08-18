package com.busanbank.card.admin.controller;

import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.busanbank.card.admin.dto.VerifyLogDto;
import com.busanbank.card.admin.service.AdminVerifyLogService;

@Controller
@RequestMapping("/admin/verify")
public class AdminVerifyLogController {

    private final AdminVerifyLogService verifyLogService;

    public AdminVerifyLogController(AdminVerifyLogService verifyLogService) {
        this.verifyLogService = verifyLogService;
    }

    @GetMapping("/logs")
    public String showLogs(Model model) {
        model.addAttribute("logs", verifyLogService.getAllLogs());
        return "admin/verify/logs"; // JSP
    }
}

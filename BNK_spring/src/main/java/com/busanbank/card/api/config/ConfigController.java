package com.busanbank.card.api.config;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/config")
public class ConfigController {

    @GetMapping("/base-url")
    public String getBaseUrl(HttpServletRequest request) {
        String ip = request.getLocalAddr(); // 또는 getServerName()
        return "http://" + ip + ":8090"; // 포트 고정이라면 포함
    }
}

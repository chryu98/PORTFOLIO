package com.busanbank.card.common.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/chat")
public class ChatViewController {

    @GetMapping("/user")
    public String userChatPage() {
        return "user/userChat";
    }

    public String adminChatPage() {
        return "admin/adminChat";
    }
}

package com.busanbank.card.chatbot.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class CardChatBotController {

    @GetMapping("card/chatbot")
    public String cardChatBotPage(HttpSession session, Model model) {
        String username = (String) session.getAttribute("loginUsername");

		/*
		 * if (username == null) { model.addAttribute("msg", "로그인이 필요한 서비스입니다."); return
		 * "user/userLogin"; }
		 */

        model.addAttribute("username", username);
        return "chatbot/cardChatBot"; // 이 경로에 JSP 있음
    }
}

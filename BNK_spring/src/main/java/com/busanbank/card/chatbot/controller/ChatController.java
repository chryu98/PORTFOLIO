package com.busanbank.card.chatbot.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ChatController {

	@GetMapping("/chatbot")
	public String showChatbotPage() {
		System.out.println(">>> Chatbot Controller 호출됨!");
		return "chatbot/chatbot";
	}
}

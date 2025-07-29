package com.busanbank.card.user.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/session")
public class SessionController {

	@PostMapping("/keep-session")
	@ResponseBody
	public Map<String, Object> keepSession(HttpSession session) {
		session.setMaxInactiveInterval(1200);
		int remainingSeconds = session.getMaxInactiveInterval();

		Map<String, Object> result = new HashMap<>();
		result.put("remainingSeconds", remainingSeconds);
		return result;
	}
}

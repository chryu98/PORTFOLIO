package com.busanbank.card.user.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;

import jakarta.servlet.http.HttpSession;

@Service
public class SessionService {

	@Autowired
	private IUserDao userDao;
	
	public UserDto prepareLoginUserAndSession(HttpSession session, Model model) {
        String username = (String) session.getAttribute("loginUsername");
        if (username == null) {
            return null;
        }

        session.setMaxInactiveInterval(1200); // 20분
        int remainingSeconds = session.getMaxInactiveInterval();
        model.addAttribute("remainingSeconds", remainingSeconds);

        UserDto loginUser = userDao.findByUsername(username);
        model.addAttribute("loginUser", loginUser);

        return loginUser;
    }
}

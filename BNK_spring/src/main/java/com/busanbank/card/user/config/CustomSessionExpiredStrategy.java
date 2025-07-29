package com.busanbank.card.user.config;

import java.io.IOException;

import org.springframework.security.web.session.SessionInformationExpiredEvent;
import org.springframework.security.web.session.SessionInformationExpiredStrategy;
import org.springframework.stereotype.Component;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class CustomSessionExpiredStrategy implements SessionInformationExpiredStrategy {

	@Override
	public void onExpiredSessionDetected(SessionInformationExpiredEvent event) throws IOException, ServletException {
		
		HttpServletRequest request = event.getRequest();
        HttpServletResponse response = event.getResponse();

        request.setAttribute("expired", true);
        request.getRequestDispatcher("/user/login").forward(request, response);
	}

}

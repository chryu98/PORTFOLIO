package com.busanbank.card.user.config;

import java.io.IOException;

import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Component
public class CustomLoginSuccessHandler implements AuthenticationSuccessHandler  {

	@Override
	public void onAuthenticationSuccess(HttpServletRequest request, 
										HttpServletResponse response,
										Authentication authentication) throws IOException, ServletException {
		
		CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
		
		HttpSession session = request.getSession();
		
		session.setAttribute("loginRole", userDetails.getRole());
		session.setAttribute("loginUsername", userDetails.getUsername());
		//2025-07-15 suwol
		session.setAttribute("loginMemberNo", userDetails.getMemberNo());
		//왜 이게 없는거지?
		session.setAttribute("loginUser", userDetails); 
		
		response.sendRedirect("/");
	}

}

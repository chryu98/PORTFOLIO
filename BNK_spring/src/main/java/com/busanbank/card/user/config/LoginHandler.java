package com.busanbank.card.user.config;

import java.io.IOException;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

public class LoginHandler {

	public static class RestLoginSuccessHandler implements AuthenticationSuccessHandler {
	    @Override
	    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
	                                        Authentication authentication) throws IOException {
	        
	    	CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
	    	
	    	//세션에 사용자 정보 저장
	    	HttpSession session = request.getSession();
	        session.setAttribute("loginUser", userDetails);
	        session.setAttribute("loginUsername", userDetails.getUsername());
	        session.setAttribute("loginRole", userDetails.getRole());
	        session.setAttribute("loginMemberNo", userDetails.getMemberNo());
	        
	        //JSON 응답
	    	response.setStatus(HttpServletResponse.SC_OK);
	        response.setContentType("application/json");
	        response.getWriter().write("{\"message\": \"로그인 성공\"}");
	    }
	}

	public static class RestLoginFailureHandler implements AuthenticationFailureHandler {
	    @Override
	    public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response,
	                                        AuthenticationException exception) throws IOException {
	        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
	        response.setContentType("application/json");
	        response.getWriter().write("{\"message\": \"로그인 실패\"}");
	    }
	}

}

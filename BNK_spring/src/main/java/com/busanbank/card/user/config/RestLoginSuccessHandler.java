package com.busanbank.card.user.config;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import com.busanbank.card.cardapply.config.JwtTokenProvider;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@Component
public class RestLoginSuccessHandler implements AuthenticationSuccessHandler {
	
	@Autowired
	private IUserDao userDao;
	
	@Autowired
	private JwtTokenProvider jwtTokenProvider;
	
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
                                        Authentication authentication) throws IOException {
    	
    	CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
    	UserDto loginUser = userDao.findByUsername(userDetails.getUsername());
    	System.out.println("로그인 유저: " + loginUser);
    	//세션에 사용자 정보 저장
    	HttpSession session = request.getSession();
        session.setAttribute("loginUser", loginUser);
        session.setAttribute("loginUsername", userDetails.getUsername());
        session.setAttribute("loginRole", userDetails.getRole());
        session.setAttribute("loginMemberNo", userDetails.getMemberNo());
        
        UserDto user = userDao.findByUsername(loginUser.getUsername());
        
        //JWT 토큰 생성
        var roles = authentication.getAuthorities().stream()
                     .map(auth -> auth.getAuthority())
                     .toList();
        String token = jwtTokenProvider.createToken(userDetails.getUsername(), user.getMemberNo(), user.getName(), roles);
        
        //JSON 응답 (토큰 포함)
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType("application/json; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        String json = String.format("{\"message\":\"로그인 성공\", \"token\":\"%s\", \"memberNo\":%d}",
                token, userDetails.getMemberNo());
        response.getWriter().write(json);
    }
}

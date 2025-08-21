package com.busanbank.card.user.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.session.SessionInformation;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.cardapply.config.JwtTokenProvider;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/user/api")
public class UserRestController {

	@Autowired
	private AuthenticationManager authenticationManager;
	@Autowired
	private SessionRegistry sessionRegistry;
	@Autowired
	private JwtTokenProvider jwtTokenProvider;
	@Autowired
	private IUserDao userDao;
	
	@PostMapping(value = "/login", produces = "application/json; charset=UTF-8")
	public ResponseEntity<?> login(@RequestBody Map<String, String> loginRequest, HttpServletRequest request) {
		
		Map<String, Object> response = new HashMap<>();
		
		String username = loginRequest.get("username");
		String password = loginRequest.get("password");

		System.out.println("username: " + username);
		
		try {
			Authentication authentication = authenticationManager
					.authenticate(new UsernamePasswordAuthenticationToken(username, password));
			SecurityContextHolder.getContext().setAuthentication(authentication);

			//인증 성공 시 JWT 토큰 생성 (JwtTokenProvider는 직접 구현하셨다고 가정)
	        List<String> roles = authentication.getAuthorities().stream()
	                            .map(auth -> auth.getAuthority())
	                            .collect(Collectors.toList());

			
	        UserDto user = userDao.findByUsername(username); // userDao에서 사용자 정보 가져오기
	        int memberNo = user.getMemberNo();
	        String name = user.getName();
	        
	        String token = jwtTokenProvider.createToken(username, name, roles);
	        
			response.put("success", true);
			response.put("message", "로그인 성공");
			response.put("token", token);
			response.put("memberNo", memberNo);
			
			return ResponseEntity.ok(response);

		} catch (BadCredentialsException e) {
			response.put("success", false);
			response.put("message", "아이디 또는 비밀번호가 올바르지 않습니다.");
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);

		} catch (AuthenticationException e) {
			response.put("success", false);
			response.put("message", "로그인 실패");
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
		}
	}

	@GetMapping("/session-status")
	public ResponseEntity<?> sessionStatus(HttpSession session) {
	    Map<String, Object> response = new HashMap<>();

	    // 로그인 유저 객체
	    Object loginUser = session.getAttribute("loginUser");
	    if (loginUser == null) {
	        response.put("status", "expired");
	        response.put("message", "세션이 만료되었습니다.");
	        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
	    }

	    // username은 별도로 세션에 저장된 loginUsername에서 가져옴
	    String username = (String) session.getAttribute("loginUsername");
	    if (username == null || username.isEmpty()) {
	        response.put("status", "expired");
	        response.put("message", "세션이 만료되었습니다.");
	        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
	    }

	    // 현재 로그인된 사용자의 활성 세션 목록 조회
	    List<SessionInformation> sessions = sessionRegistry.getAllSessions(username, false);

	    if (sessions.size() > 1) {
	        response.put("status", "duplicated");
	        response.put("message", "다른 위치에서 로그인되어 로그아웃 되었습니다.");
	        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
	    }

	    // 정상 세션 상태
	    response.put("status", "active");
	    return ResponseEntity.ok(response);
	}
	
	@PostMapping("/logout")
    public ResponseEntity<?> logout(HttpServletRequest request) {
        // 서버 세션 제거
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }

        // JWT는 클라이언트가 관리하므로 localStorage에서 제거
        Map<String, String> res = new HashMap<>();
        res.put("message", "로그아웃 되었습니다.");
        return ResponseEntity.ok(res);
    }
	
//	@GetMapping("/session-expired")
//	public ResponseEntity<?> sessionExpired() {
//		Map<String, Object> result = new HashMap<>();
//		result.put("message", "인증이 만료되어 로그아웃 되었습니다.");
//		return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
//	}
//
//	@GetMapping("/duplicated-login")
//	public ResponseEntity<?> duplicatedLogin() {
//		Map<String, Object> result = new HashMap<>();
//		result.put("message", "다른 위치에서 로그인되어 로그아웃 되었습니다.");
//		return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
//	}
}
package com.busanbank.card.user.controller;

import java.security.Principal;
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
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.cardapply.config.JwtTokenProvider;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.PushMemberDto;
import com.busanbank.card.user.dto.UserCardDto;
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
	@Autowired
	private BCryptPasswordEncoder bCryptPasswordEncoder;

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

			// 인증 성공 시 JWT 토큰 생성 (JwtTokenProvider는 직접 구현하셨다고 가정)
			List<String> roles = authentication.getAuthorities().stream().map(auth -> auth.getAuthority())
					.collect(Collectors.toList());

			UserDto user = userDao.findByUsername(username); // userDao에서 사용자 정보 가져오기
			int memberNo = user.getMemberNo();
			String name = user.getName();

			String token = jwtTokenProvider.createToken(username, memberNo, name, roles);

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

	@GetMapping("/get-info")
	public ResponseEntity<Map<String, Object>> getMyPage(Principal principal) {
		Map<String, Object> response = new HashMap<>();
		// 로그인한 사용자의 username으로 정보 조회
		UserDto userDto = userDao.findByUsername(principal.getName());
		String pushYn = userDao.findPushYn(userDto.getMemberNo());
		if (pushYn == null || pushYn.isBlank()) pushYn = "N";
		
		response.put("user", userDto);
		response.put("pushYn", pushYn);
		
		return ResponseEntity.ok(response);
	}

	@PostMapping("/update")
	public ResponseEntity<Map<String, Object>> updateRest(UserDto user, HttpSession session,
			@RequestHeader(value = "Authorization", required = false) String authHeader,
			@RequestParam(value = "extraAddress", required = false) String extraAddress) {

		System.out.println("username=" + user.getUsername());
		System.out.println("address1=" + user.getAddress1());
		System.out.println("extraAddress=" + extraAddress);

		Map<String, Object> result = new HashMap<>();
		String loginUsername = null;

		// 앱 JWT 인증
		if (authHeader != null && authHeader.startsWith("Bearer ")) {
			String token = authHeader.substring(7);
			if (jwtTokenProvider.validateToken(token)) {
				loginUsername = jwtTokenProvider.getUsername(token); // 여기서 username 추출
			}
		}

		// 웹 세션 인증
		if (loginUsername == null && session.getAttribute("loginUsername") != null) {
			loginUsername = (String) session.getAttribute("loginUsername");
		}

		if (loginUsername == null || !loginUsername.equals(user.getUsername())) {
			result.put("success", false);
			result.put("msg", "잘못된 접근입니다.");
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
		}

		// DB 사용자 조회
		UserDto loginUser = userDao.findByUsername(user.getUsername());
		if (loginUser == null) {
			result.put("success", false);
			result.put("msg", "존재하지 않는 사용자입니다.");
			return ResponseEntity.badRequest().body(result);
		}

		// 비밀번호 처리
		if (user.getPassword() != null && !user.getPassword().isEmpty()) {
			if (bCryptPasswordEncoder.matches(user.getPassword(), loginUser.getPassword())) {
				result.put("success", false);
				result.put("msg", "기존 비밀번호와 동일합니다. 새로운 비밀번호를 입력해주세요.");
				return ResponseEntity.badRequest().body(result);
			}
			user.setPassword(bCryptPasswordEncoder.encode(user.getPassword()));
		} else {
			user.setPassword(loginUser.getPassword());
		}

		// 주소 처리
		// 플러터에서 address1에 이미 "(참고주소)" 포함 → 그대로 저장
		user.setAddress1(user.getAddress1());

		// memberNo 세팅 (DB 업데이트 위해 필수)
		user.setMemberNo(loginUser.getMemberNo());

		// DB 수정
		try {
			int updatedRows = userDao.updateMember(user); // 반환값 확인 가능
			System.out.println("updatedRows=" + updatedRows);
			if (updatedRows <= 0) {
				result.put("success", false);
				result.put("msg", "회원정보 수정 실패");
				return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(result);
			}
		} catch (Exception e) {
			result.put("success", false);
			result.put("msg", "회원정보 수정 중 오류 발생");
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(result);
		}

		result.put("success", true);
		result.put("msg", "회원정보가 수정되었습니다.");
		return ResponseEntity.ok(result);
	}
	
	@PostMapping("/push-member")
	public ResponseEntity<?> updatePushMember(@RequestBody PushMemberDto pushMember) {
	    int updated = userDao.upsertPushMember(pushMember);
	    return ResponseEntity.ok(Map.of("success", updated > 0));
	}
	
	@PostMapping("/card-list")
	public ResponseEntity<List<UserCardDto>> getCardApplications(Principal principal) {
	    // 로그인한 사용자의 memberNo 조회
	    UserDto user = userDao.findByUsername(principal.getName());
	    int memberNo = user.getMemberNo();

	    List<UserCardDto> cards = userDao.getUserCardList(memberNo);
	    return ResponseEntity.ok(cards);
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
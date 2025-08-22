package com.busanbank.card.cardapply.controller;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.cardapply.config.JwtTokenProvider;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;

import lombok.Data;

@RestController
@RequestMapping("/jwt/api")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private IUserDao userDao;
    
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        Authentication auth = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword())
        );

        List<String> roles = auth.getAuthorities().stream()
            .map(r -> r.getAuthority())
            .collect(Collectors.toList());

        UserDto user = userDao.findByUsername(loginRequest.getUsername());
        String name = user.getName();
        
        String token = jwtTokenProvider.createToken(loginRequest.getUsername(), user.getMemberNo(), user.getName(), roles);

        return ResponseEntity.ok(new JwtResponse(token));
    }

    @Data
    static class LoginRequest {
        private String username;
        private String password;
    }

    @Data
    static class JwtResponse {
        private final String token;
    }
}

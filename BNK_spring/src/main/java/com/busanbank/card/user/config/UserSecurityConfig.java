package com.busanbank.card.user.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.security.core.session.SessionRegistryImpl;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.session.HttpSessionEventPublisher;

import jakarta.servlet.http.HttpSession;

@Configuration
@EnableWebSecurity
@Order(2)
public class UserSecurityConfig {

    @Autowired
    private CustomLoginSuccessHandler customLoginSuccessHandler;

    @Autowired
    private CustomSessionExpiredStrategy customSessionExpiredStrategy;

    @Bean
    BCryptPasswordEncoder bCryptPasswordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    SessionRegistry sessionRegistry() {
        return new SessionRegistryImpl();
    }

    @Bean
    static ServletListenerRegistrationBean<HttpSessionEventPublisher> httpSessionEventPublisher() {
        return new ServletListenerRegistrationBean<>(new HttpSessionEventPublisher());
    }

    @Bean(name = "userFilterChain")
    SecurityFilterChain userFilterChain(HttpSecurity http) throws Exception {

        http.securityMatcher("/regist/**", "/user/chat/**", "/user/**", "/loginProc", "/logout")
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll()
            );

        http.formLogin(auth -> auth
            .loginPage("/user/login")
            .loginProcessingUrl("/loginProc")
            .successHandler(customLoginSuccessHandler)
            .failureUrl("/user/login?error=true")
            .permitAll()
        );

        http.logout(logout -> logout
            .logoutUrl("/logout")
            .logoutSuccessHandler((request, response, authentication) -> {
                // 회원 로그아웃 시 관리자 세션 보존을 위해 전체 세션 무효화는 하지 않음
                HttpSession session = request.getSession(false);
                if (session != null) {
                	
                	// 사용자 인증 정보만 제거
                	session.removeAttribute("loginUser");
                	session.removeAttribute("SPRING_SECURITY_CONTEXT");
                	session.removeAttribute("loginUsername");
                	session.removeAttribute("loginMemberNo");
                	session.removeAttribute("loginRole");
                }

                // Spring Security 인증 컨텍스트 제거
                SecurityContextHolder.clearContext();

                // 로그아웃 후 리다이렉트
                String expired = request.getParameter("expired");
                if (expired != null) {
                    response.sendRedirect("/user/login?expired=true");
                } else {
                    response.sendRedirect("/user/login?logout=true");
                }
            })
            .invalidateHttpSession(false)
            .permitAll()
        );

        http.sessionManagement(session -> session
            .sessionFixation().none()  // 세션 ID 고정 (기존 세션 그대로 사용)
            .maximumSessions(1)
            .expiredSessionStrategy(customSessionExpiredStrategy)
            .maxSessionsPreventsLogin(false)
            .sessionRegistry(sessionRegistry())
        );

        http.csrf(csrf -> csrf.disable());

        return http.build();
    }
}

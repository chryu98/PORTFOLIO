package com.busanbank.card.admin.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

import com.busanbank.card.admin.session.AdminSession;

@Configuration
@EnableWebSecurity
@Order(1)
public class SecurityConfig {

	@Bean(name = "adminFilterChain")
    public SecurityFilterChain adminFilterChain(HttpSecurity http, AdminSession adminSession) throws Exception {
        http
            .securityMatcher("/admin/**")
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/admin/Search/searchlog/**","/admin/Mainpage","/admin/adminLoginForm", "/admin/login", "/admin/logout").permitAll()
                .anyRequest().access((authContext, context) -> {
                    boolean loggedIn = adminSession.isLoggedIn();
                    return new org.springframework.security.authorization.AuthorizationDecision(loggedIn);
                })
            )
            .exceptionHandling(exception -> 
                exception
                    .authenticationEntryPoint((request, response, authException) -> {
                        response.sendRedirect("/admin/adminLoginForm");
                    })
            )
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session
                .maximumSessions(1)
                .maxSessionsPreventsLogin(true)
            );

        return http.build();
    }

}


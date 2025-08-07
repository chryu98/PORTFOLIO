package com.busanbank.card.admin.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import com.busanbank.card.admin.session.AdminSession;

import java.util.List;

@Configuration
@EnableWebSecurity
@Order(1)
public class SecurityConfig {

    @Bean(name = "adminFilterChain")
    public SecurityFilterChain adminFilterChain(HttpSecurity http, AdminSession adminSession) throws Exception {
        http
            .cors() // CORS 활성화
            .and()
            .securityMatcher("/admin/**")
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(
                    "/admin/Search/searchlog/**",
                    "/admin/Mainpage",
                    "/admin/adminLoginForm",
                    "/admin/login",
                    "/admin/logout",
                    "/admin/pdf/view/**"
                ).permitAll()
                .requestMatchers(HttpMethod.DELETE, "/admin/**").authenticated()
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

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowCredentials(true);
        config.setAllowedOriginPatterns(List.of("*")); // 여기에 프론트 주소
        config.setAllowedHeaders(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}

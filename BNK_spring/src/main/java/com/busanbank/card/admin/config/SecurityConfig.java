package com.busanbank.card.admin.config;

import org.springframework.beans.factory.annotation.Autowired;
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

	@Autowired
    private CorsConfigurationSource corsConfigurationSource;
	
    @Bean(name = "adminFilterChain")
    public SecurityFilterChain adminFilterChain(HttpSecurity http, AdminSession adminSession) throws Exception {
        http
        	.cors(cors -> cors.configurationSource(corsConfigurationSource))
            .securityMatcher("/admin/**")
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(
                    "/admin/Search/searchlog/**",
                    "/admin/Mainpage",
                    "/admin/adminLoginForm",
                    "/admin/login",
                    "/admin/logout",
                    "/admin/pdf/**"
                ).permitAll()
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
            )
        .headers(h -> {
            h.frameOptions(f -> f.sameOrigin());                         // 같은 오리진에서만 iframe 허용
            h.contentSecurityPolicy(csp -> csp.policyDirectives(
                "frame-ancestors 'self'"                                 // (선택) CSP로도 명시
            ));
        });

        return http.build();
    }
}

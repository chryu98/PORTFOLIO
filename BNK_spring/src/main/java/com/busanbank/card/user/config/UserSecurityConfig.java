package com.busanbank.card.user.config;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.session.SessionRegistry;
import org.springframework.security.core.session.SessionRegistryImpl;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.session.HttpSessionEventPublisher;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import jakarta.servlet.http.HttpSession;

@Configuration
@EnableWebSecurity
@Order(2)
public class UserSecurityConfig {

    @Autowired
    private CustomLoginSuccessHandler customLoginSuccessHandler;

    @Autowired
    private CustomSessionExpiredStrategy customSessionExpiredStrategy;

    @Autowired
    private CustomUserDetailsService userDetailsService;
    
    @Autowired
    private RestLoginSuccessHandler restLoginSuccessHandler;
    @Autowired
    private RestLoginFailureHandler restLoginFailureHandler;
    
    @Bean
    BCryptPasswordEncoder bCryptPasswordEncoder() {
        return new BCryptPasswordEncoder();
    }

//    @Bean
//    SessionInformationExpiredStrategy customSessionExpiredStrategy() {
//        return new CustomSessionExpiredStrategy();
//    }
    
    @Bean
    SessionRegistry sessionRegistry() {
        return new SessionRegistryImpl();
    }

    @Bean
    static ServletListenerRegistrationBean<HttpSessionEventPublisher> httpSessionEventPublisher() {
        return new ServletListenerRegistrationBean<>(new HttpSessionEventPublisher());
    }
    
    @Bean
    AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }

    @Bean
    DaoAuthenticationProvider daoAuthenticationProvider() {
    	DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    	provider.setUserDetailsService(userDetailsService); // 실제 사용자 서비스 주입 필요
    	provider.setPasswordEncoder(bCryptPasswordEncoder());
    	return provider;
    }

    @Bean(name = "userFilterChain")
    SecurityFilterChain userFilterChain(HttpSecurity http, AuthenticationManager authenticationManager) throws Exception {

    	// REST 로그인용 커스텀 필터
        CustomRestAuthenticationFilter restLoginFilter = new CustomRestAuthenticationFilter(authenticationManager);
        restLoginFilter.setAuthenticationSuccessHandler(restLoginSuccessHandler);
        restLoginFilter.setAuthenticationFailureHandler(restLoginFailureHandler);
    	
        http
        .securityMatcher("/regist/**", "/user/chat/**", "/user/**", "/user/api/**", "/loginProc", "/logout")
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/user/api/**").permitAll()
            .anyRequest().permitAll()
        )
        .cors()  // 반드시 추가
        .and()
        .csrf(csrf -> csrf.disable())
        .formLogin(auth -> auth
            .loginPage("/user/login")
            .loginProcessingUrl("/loginProc")
            .successHandler(customLoginSuccessHandler)
            .failureUrl("/user/login?error=true")
            .permitAll()
        )
        .logout(logout -> logout
            .logoutUrl("/user/api/logout")
            .logoutSuccessHandler((request, response, authentication) -> {
                HttpSession session = request.getSession(false);
                if (session != null) {
                    session.removeAttribute("loginUser");
                    session.removeAttribute("SPRING_SECURITY_CONTEXT");
                    session.removeAttribute("loginUsername");
                    session.removeAttribute("loginMemberNo");
                    session.removeAttribute("loginRole");
                }
                SecurityContextHolder.clearContext();

                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"message\":\"로그아웃 되었습니다.\"}");
                response.getWriter().flush();
            })
        )
        .sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
            .sessionFixation().none()
            .maximumSessions(1)
            .expiredSessionStrategy(customSessionExpiredStrategy)
            .maxSessionsPreventsLogin(false)
            .sessionRegistry(sessionRegistry())
        );

    http.addFilterBefore(restLoginFilter, UsernamePasswordAuthenticationFilter.class);

    return http.build();
    }
}

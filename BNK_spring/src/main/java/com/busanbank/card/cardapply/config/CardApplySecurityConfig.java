package com.busanbank.card.cardapply.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import com.busanbank.card.user.config.CustomUserDetailsService;

@Configuration("cardApplySecurityConfig")
@Order(2)
public class CardApplySecurityConfig {

    private final JwtTokenProvider jwt;
    private final CustomUserDetailsService uds;

    public CardApplySecurityConfig(JwtTokenProvider jwt, CustomUserDetailsService uds) {
        this.jwt = jwt;
        this.uds = uds;
    }

    @Bean(name = "cardApplySecurityFilterChain")
    SecurityFilterChain cardApplyFilterChain(HttpSecurity http) throws Exception {
        http
            // 🔴 여기 '/api/card/apply/**' 추가
            .securityMatcher("/jwt/api/**", "/card/apply/api/**", "/api/card/apply/**")
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/jwt/api/login").permitAll()
                // 두 prefix 모두 인증 필요
                .requestMatchers("/card/apply/api/**", "/api/card/apply/**").authenticated()
                .anyRequest().permitAll()
            )
            .exceptionHandling(ex -> ex.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
            .addFilterBefore(new JwtTokenFilter(jwt, uds), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}

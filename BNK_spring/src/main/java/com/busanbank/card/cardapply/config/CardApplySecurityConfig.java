package com.busanbank.card.cardapply.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import com.busanbank.card.user.config.CustomUserDetailsService;

@Configuration("cardApplySecurityConfig")
@Order(0) // 최우선
public class CardApplySecurityConfig {

  private final JwtTokenProvider jwt;
  private final CustomUserDetailsService uds;

  public CardApplySecurityConfig(JwtTokenProvider jwt, CustomUserDetailsService uds) {
    this.jwt = jwt;
    this.uds = uds;
  }

  @Bean
  JwtTokenFilter jwtAuthenticationFilter() {
    return new JwtTokenFilter(jwt, uds);
  }

  @Bean(name = "cardApplySecurityFilterChain")
  SecurityFilterChain cardApplyFilterChain(HttpSecurity http) throws Exception {
    http
      // ✅ 이 체인이 다루는 경로 확장: 서명 이미지 엔드포인트 포함
      .securityMatcher("/jwt/api/**", "/card/apply/api/**", "/api/card/apply/**", "/card/apply/sign/**")
      .cors(Customizer.withDefaults())
      .csrf(csrf -> csrf.disable())
      .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .authorizeHttpRequests(auth -> auth
          .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

          // ✅ JWT 로그인/리프레시 허용
          .requestMatchers("/jwt/api/login", "/jwt/api/refresh").permitAll()

          // 공개 GET API (약관/정적 조회 등)
          .requestMatchers(HttpMethod.GET, "/api/card/apply/card-terms").permitAll()

          // ✅ 서명 이미지(바이트) 공개 (보호 원하면 authenticated()로 바꿔도 됨)
          .requestMatchers(HttpMethod.GET, "/card/apply/sign/**").permitAll()

          // 나머지 카드 발급/서명 API는 인증 필요
          .requestMatchers("/card/apply/api/**", "/api/card/apply/**").authenticated()

          .anyRequest().permitAll()
      )
      .exceptionHandling(ex -> ex
          .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
      .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);

    return http.build();
  }
}

// com/busanbank/card/cardapply/config/CardApplySecurityConfig.java
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

@Configuration("cardApplySecurityConfig") // 고유한 빈 이름으로 admin 보안설정과 충돌 방지
@Order(2) // (선택) admin 쪽이 @Order(1)라면 이 체인은 이후에 평가
public class CardApplySecurityConfig {
  private final JwtTokenProvider jwt;
  private final CustomUserDetailsService uds;

  public CardApplySecurityConfig(JwtTokenProvider jwt, CustomUserDetailsService uds) {
    this.jwt = jwt;
    this.uds = uds;
  }

  @Bean(name = "cardApplySecurityFilterChain") // 고유한 체인 이름
  SecurityFilterChain cardApplyFilterChain(HttpSecurity http) throws Exception {
    http
      // 이 체인이 담당할 경로만 한정
      .securityMatcher("/jwt/api/**", "/card/apply/api/**")
      .csrf(csrf -> csrf.disable())
      // ★ JWT만 사용: 세션 완전 비활성화
      .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      // 인가 규칙
      .authorizeHttpRequests(auth -> auth
        .requestMatchers("/jwt/api/login").permitAll()
        .requestMatchers("/card/apply/api/**").authenticated()
        .anyRequest().permitAll()
      )
      // ★ 미인증 접근은 무조건 401 반환
      .exceptionHandling(ex -> ex.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
      // (옵션) CORS 필요하면 주석 해제
      //.cors(Customizer.withDefaults())
      // ★ JWT 필터 연결
      .addFilterBefore(new JwtTokenFilter(jwt, uds), UsernamePasswordAuthenticationFilter.class);

    return http.build();
  }

  // ⚠️ PasswordEncoder / AuthenticationManager 는 admin 설정에 이미 있으면 여기서 만들지 마세요.
  // 꼭 필요할 때만 이름 다르게 추가하세요.
}

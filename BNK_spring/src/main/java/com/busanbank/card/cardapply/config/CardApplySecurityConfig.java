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
import org.springframework.security.config.Customizer;
import org.springframework.http.HttpMethod;

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
      .securityMatcher("/jwt/api/**", "/card/apply/api/**", "/api/card/apply/**")
      .cors(Customizer.withDefaults())
      .csrf(csrf -> csrf.disable())
      .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .authorizeHttpRequests(auth -> auth
          .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
          .requestMatchers("/jwt/api/login").permitAll()
          .requestMatchers(HttpMethod.GET, "/api/card/apply/card-terms").permitAll()
          .requestMatchers("/card/apply/api/**", "/api/card/apply/**").authenticated()
          .anyRequest().permitAll()
      )
      .exceptionHandling(ex -> ex.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
      .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);

    return http.build();
  }
}


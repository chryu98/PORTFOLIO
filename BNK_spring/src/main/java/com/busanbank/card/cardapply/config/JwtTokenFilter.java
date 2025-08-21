package com.busanbank.card.cardapply.config;

import java.io.IOException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

import com.busanbank.card.user.config.CustomUserDetailsService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

public class JwtTokenFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final CustomUserDetailsService userDetailsService;

    // ✅ 화이트리스트(토큰 검사 스킵)
    private static final AntPathMatcher matcher = new AntPathMatcher();
    private static final String[] WHITELIST = {
    	    "/", "/user/login", "/signup", "/regist/**", "/user/regist/**", "/auth/**",
    	    "/css/**", "/js/**", "/images/**",
    	    "/user/api/login",
    	    "/user/api/regist/**"   // ✅ 추가
    	};

    public JwtTokenFilter(JwtTokenProvider jwtTokenProvider, CustomUserDetailsService userDetailsService) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.userDetailsService = userDetailsService;
    }

    private boolean isWhitelisted(String uri) {
        for (String p : WHITELIST) if (matcher.match(p, uri)) return true;
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        // ✅ CORS preflight 및 화이트리스트는 바로 통과
        if ("OPTIONS".equalsIgnoreCase(request.getMethod()) || isWhitelisted(request.getRequestURI())) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = resolveToken(request);
        // (원하면) 디버그 레벨 로깅으로만 남겨도 됨
        // System.out.println("[JWT] Incoming token: " + (token != null ? "present" : "null"));

        // ✅ 토큰 없으면 그냥 패스 (폼 제출/공개 API에서 401 막힘 방지)
        if (token == null) {
            filterChain.doFilter(request, response);
            return;
        }

        if (jwtTokenProvider.validateToken(token)) {
            String username = jwtTokenProvider.getUsername(token);
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        filterChain.doFilter(request, response);
    }

    /** Authorization 헤더 또는 쿠키에서 토큰 추출 */
    private String resolveToken(HttpServletRequest request) {
        String bearer = request.getHeader("Authorization");
        if (bearer != null && bearer.startsWith("Bearer ")) {
            return bearer.substring(7);
        }
        // ✅ 쿠키 전략도 허용(폼 제출 시 자동 포함)
        if (request.getCookies() != null) {
            for (Cookie c : request.getCookies()) {
                if ("ACCESS_TOKEN".equals(c.getName())) {
                    return c.getValue();
                }
            }
        }
        return null;
    }
}

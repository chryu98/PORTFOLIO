package com.busanbank.card.cardapply.config;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;
import java.util.List;

import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtTokenProvider {

    // ⚠️ 실제 운영 시 환경변수/설정 파일로 관리 권장
    private final String secretKey = "verylongsecretkeythatisatleast32byteslong!";
    private final Key key = Keys.hmacShaKeyFor(secretKey.getBytes(StandardCharsets.UTF_8));
    private final long validityInMs = 3600000; // 1시간

    /** 토큰 생성 (username, memberNo, name, roles 포함) */
    public String createToken(String username, int memberNo, String name, List<String> roles) {
        Claims claims = Jwts.claims().setSubject(username);
        claims.put("memberNo", memberNo);
        claims.put("name", name);
        claims.put("roles", roles);

        Date now = new Date();
        Date expiry = new Date(now.getTime() + validityInMs);

        return Jwts.builder()
                .setClaims(claims)
                .setIssuedAt(now)
                .setExpiration(expiry)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    /** 토큰에서 username 추출 */
    public String getUsername(String token) {
        try {
            return Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .getSubject();
        } catch (Exception e) {
            System.err.println("[JWT] Failed to extract username: " + e.getMessage());
            return null;
        }
    }
    
    /** 토큰에서 name 추출 */
    public String getName(String token) {
        try {
            return Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .get("name", String.class); // payload에서 name 꺼내기
        } catch (Exception e) {
            System.err.println("[JWT] Failed to extract name: " + e.getMessage());
            return null;
        }
    }

    
    public Integer getMemberNo(String token) {
        try {
            return Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .get("memberNo", Integer.class);
        } catch (Exception e) {
            System.err.println("[JWT] Failed to extract memberNo: " + e.getMessage());
            return null;
        }
    }
    /** 토큰 유효성 검사 (로그 추가) */
    public boolean validateToken(String token) {
        try {
            Jws<Claims> claims = Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token);

            boolean expired = claims.getBody().getExpiration().before(new Date());
            if (expired) {
                System.err.println("[JWT] Token expired at: " + claims.getBody().getExpiration());
                return false;
            }
            return true;
        } catch (JwtException e) {
            System.err.println("[JWT] Validation failed: " + e.getMessage());
            return false;
        } catch (IllegalArgumentException e) {
            System.err.println("[JWT] Token is null or empty");
            return false;
        }
    }
}


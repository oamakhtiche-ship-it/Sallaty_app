package com.Sallaty.Sallaty.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;

@Component
public class JwtUtil {

    // ═══════════════════════════════════════════════
    //  TOKEN TYPE
    // ═══════════════════════════════════════════════
    public enum TokenType {
        ACCESS,
        REFRESH
    }

    // ═══════════════════════════════════════════════
    //  CONFIG
    // ═══════════════════════════════════════════════
    @Value("${jwt.secret}")
    private String secretKey;

    @Value("${jwt.access.minutes:1440}")
    private long accessMinutes;

    @Value("${jwt.refresh.days:7}")
    private long refreshDays;

    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(
            secretKey.getBytes());
    }

    // ═══════════════════════════════════════════════
    //  generateToken() — ACCESS
    // ═══════════════════════════════════════════════
    public String generateToken(String email) {
        return Jwts.builder()
            .setSubject(email)
            .claim("type", TokenType.ACCESS.name())
            .setIssuedAt(new Date())
            .setExpiration(new Date(
                System.currentTimeMillis()
                + accessMinutes * 60 * 1000))
            .signWith(getSigningKey(),
                SignatureAlgorithm.HS256)
            .compact();
    }

    // ═══════════════════════════════════════════════
    //  generateRefreshToken() — REFRESH
    // ═══════════════════════════════════════════════
    public String generateRefreshToken(String email) {
        return Jwts.builder()
            .setSubject(email)
            .claim("type", TokenType.REFRESH.name())
            .setIssuedAt(new Date())
            .setExpiration(new Date(
                System.currentTimeMillis()
                + refreshDays * 24 * 60 * 60 * 1000))
            .signWith(getSigningKey(),
                SignatureAlgorithm.HS256)
            .compact();
    }

    // ═══════════════════════════════════════════════
    //  getEmail()
    // ═══════════════════════════════════════════════
    public String getEmail(String token) {
        return getClaims(token).getSubject();
    }

    // ═══════════════════════════════════════════════
    //  getTokenType()
    // ═══════════════════════════════════════════════
    public TokenType getTokenType(String token) {
        String type = getClaims(token)
            .get("type", String.class);
        return TokenType.valueOf(type);
    }

    // ═══════════════════════════════════════════════
    //  isTokenValid()
    // ═══════════════════════════════════════════════
    public boolean isTokenValid(String token) {
        try {
            return !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    // ═══════════════════════════════════════════════
    //  isTokenExpired()
    // ═══════════════════════════════════════════════
    private boolean isTokenExpired(String token) {
        return getClaims(token)
            .getExpiration()
            .before(new Date());
    }

    // ═══════════════════════════════════════════════
    //  getClaims()
    // ═══════════════════════════════════════════════
    private Claims getClaims(String token) {
        return Jwts.parserBuilder()
            .setSigningKey(getSigningKey())
            .build()
            .parseClaimsJws(token)
            .getBody();
    }
}
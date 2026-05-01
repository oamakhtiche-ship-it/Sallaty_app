package com.Sallaty.Sallaty.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // ═══════════════════════════════════════════════
    //  doFilterInternal()
    // ═══════════════════════════════════════════════
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        // 1. Récupérer header Authorization
        String authHeader =
            request.getHeader("Authorization");

        // 2. Vérifier format Bearer token
        if (authHeader == null ||
            !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 3. Extraire token
        String token = authHeader.substring(7);

        // 4. Valider token
        if (!jwtUtil.isTokenValid(token)) {
            filterChain.doFilter(request, response);
            return;
        }

        // 5. Vérifier type ACCESS
        if (jwtUtil.getTokenType(token) !=
                JwtUtil.TokenType.ACCESS) {
            filterChain.doFilter(request, response);
            return;
        }

        // 6. Extraire email
        String email = jwtUtil.getEmail(token);

        // 7. Vérifier pas déjà authentifié
        if (email != null &&
            SecurityContextHolder.getContext()
                .getAuthentication() == null) {

            // 8. Charger user
            UserDetails userDetails =
                userDetailsService
                    .loadUserByUsername(email);

            // 9. Créer authentication
            UsernamePasswordAuthenticationToken
                authToken =
                new UsernamePasswordAuthenticationToken(
                    userDetails,
                    null,
                    userDetails.getAuthorities());

            authToken.setDetails(
                new WebAuthenticationDetailsSource()
                    .buildDetails(request));

            // 10. Set dans SecurityContext
            SecurityContextHolder.getContext()
                .setAuthentication(authToken);
        }

        // 11. Continuer
        filterChain.doFilter(request, response);
    }
}
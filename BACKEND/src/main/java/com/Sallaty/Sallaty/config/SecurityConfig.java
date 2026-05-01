package com.Sallaty.Sallaty.config;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import com.Sallaty.Sallaty.security.JwtFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private JwtFilter jwtFilter;

    // ✅ CORS — autorise Flutter Web (localhost) + mobile + ngrok
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        // Autorise toutes les origines (Flutter Web, mobile, ngrok)
        config.setAllowedOriginPatterns(List.of("*"));

        // Méthodes HTTP autorisées
        config.setAllowedMethods(List.of(
            "GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"
        ));

        // Headers autorisés
        config.setAllowedHeaders(List.of("*"));

        // Expose Authorization header
        config.setExposedHeaders(List.of("Authorization"));

        // Autorise les credentials (token JWT)
        config.setAllowCredentials(true);

        // Durée du cache preflight
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source =
            new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http) throws Exception {

        http
            // ✅ CORS activé avec notre config
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth

                // ═══════════════════════════════════════════════
                //  PUBLIC — pas besoin de token
                // ═══════════════════════════════════════════════
                .requestMatchers(
                    "/api/auth/**",
                    "/api/users/uploadImage/**",
                    "/uploads/**"
                ).permitAll()

                .requestMatchers(
                    "/api/categories",
                    "/api/categories/**"
                ).permitAll()

                // ✅ OFFRES PUBLIC
                .requestMatchers(HttpMethod.GET,
                    "/api/offres/available",
                    "/api/offres/recent",
                    "/api/offres/active",
                    "/api/offres/most-reserved",
                    "/api/offres/search",
                    "/api/offres/discount"
                ).permitAll()

                .requestMatchers(HttpMethod.GET,
                    "/api/offres/wilaya/**",
                    "/api/offres/category/**",
                    "/api/offres/marchand/**"
                ).permitAll()

                .requestMatchers(HttpMethod.GET,
                    "/api/offres/price"
                ).permitAll()

                .requestMatchers(
                    "/api/marchand/get/**",
                    "/api/marchand/total-favoris/**"
                ).permitAll()

                .requestMatchers(
                    "/api/subscribe/*/subscribers",
                    "/api/subscribe/*/count"
                ).permitAll()

                .requestMatchers(
                    "/api/favoris/count/**"
                ).permitAll()

                .requestMatchers(
                    "/api/profile/public/**"
                ).permitAll()

                .requestMatchers(
                    "/api/static/**",
                    "/api/search/**"
                ).permitAll()

                .requestMatchers(
                    "/ws/**"
                ).permitAll()

                // ✅ ORDRES PUBLIC
                .requestMatchers(HttpMethod.GET,
                    "/api/ordres/offre/**",
                    "/api/ordres/reservations/**",
                    "/api/ordres/location/**"
                ).permitAll()

                // ═══════════════════════════════════════════════
                //  MARCHAND + ADMIN
                // ═══════════════════════════════════════════════
                .requestMatchers(
                    HttpMethod.POST, "/api/offres/create"
                ).hasAnyAuthority("MARCHANT", "ADMIN")

                .requestMatchers(
                    HttpMethod.PUT,
                    "/api/offres/update/**",
                    "/api/offres/archive/**",
                    "/api/offres/discount/**"
                ).hasAnyAuthority("MARCHANT", "ADMIN")

                .requestMatchers(
                    HttpMethod.DELETE, "/api/offres/photo/**"
                ).hasAnyAuthority("MARCHANT", "ADMIN")

                .requestMatchers(
                    HttpMethod.POST, "/api/offres/photo/**"
                ).hasAnyAuthority("MARCHANT", "ADMIN")

                .requestMatchers(HttpMethod.GET,
                    "/api/offres/sold-out",
                    "/api/offres/expired",
                    "/api/offres/inactive",
                    "api/marchand/statistics"
                ).hasAnyAuthority("MARCHANT", "ADMIN")

                .requestMatchers(
                    "/api/roles/marchand/**",
                    "/api/marchand/profile/**"
                ).hasAnyAuthority("MARCHANT", "ADMIN")

                // ✅ Offre par ID — public
                .requestMatchers(HttpMethod.GET, "/api/offres/**"
                ).permitAll()

                // ═══════════════════════════════════════════════
                //  ADMIN seulement
                // ═══════════════════════════════════════════════
                .requestMatchers(
                    "/api/users/block/**",
                    "/api/users/unblock/**",
                    "/api/users/delete/**",
                    "/api/roles/delete/**",
                    "/api/offres/all",
                    "/api/offres/archived",
                    "/api/offres/block/**",
                    "/api/offres/unblock/**",
                    "/api/categories/create",
                    "/api/categories/delete/**",
                    "/api/marchand/pending",
                    "/api/marchand/verified",
                    "/api/marchand/cancelled",
                    "/api/marchand/trade-register/**",
                    "/api/marchand/verify/**",
                    "/api/marchand/cancel/**",
                    "/api/marchand/reactivate/**",
                    "/api/ordres/status/**",
                    "/api/admin/**",
                    "/api/notifications/broadcast",
                    "/api/notifications/support/**"
                ).hasAuthority("ADMIN")

                // ═══════════════════════════════════════════════
                //  AUTHENTICATED — token requis
                // ═══════════════════════════════════════════════
                .requestMatchers(
                    "/api/users/**",
                    "/api/roles/**",
                    "/api/marchand/register",
                    "/api/ordres/**",
                    "/api/payments/**",
                    "/api/messages/**",
                    "/api/profile/**",
                    "/api/favoris/**",
                    "/api/subscribe/**",
                    "/api/notifications/**",
                    "/api/settings/**"
                ).authenticated()
                // ── In SecurityConfig.java, replace the old statistics rules with these: ──

// MERCHANT statistics  → authenticated + MARCHANT role
.requestMatchers(HttpMethod.GET, "/api/statistics/marchand")
    .hasAnyAuthority("MARCHANT", "ADMIN")

// CLIENT statistics → any authenticated user
.requestMatchers(HttpMethod.GET, "/api/statistics/client")
    .authenticated()
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(
                    SessionCreationPolicy.STATELESS))
            .addFilterBefore(
                jwtFilter,
                UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
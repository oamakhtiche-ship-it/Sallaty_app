package com.Sallaty.Sallaty.config;

import java.util.List;

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

    // ✅ Constantes pour éviter la duplication (SonarLint S1192)
    private static final String ROLE_MARCHANT = "MARCHANT";
    private static final String ROLE_ADMIN    = "ADMIN";

    // ✅ CORS
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    // ✅ JwtFilter injecté directement dans la méthode (SonarLint S6813 + S3305)
    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            JwtFilter jwtFilter) throws Exception {

        http
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

                .requestMatchers(HttpMethod.GET,
                    "/api/ordres/offre/**",
                    "/api/ordres/reservations/**",
                    "/api/ordres/location/**"
                ).permitAll()

                // ✅ Offre par ID — public
                .requestMatchers(HttpMethod.GET, "/api/offres/**").permitAll()

                // ═══════════════════════════════════════════════
                //  STATISTICS — règles spécifiques AVANT les générales
                // ═══════════════════════════════════════════════
                .requestMatchers(HttpMethod.GET, "/api/statistics/marchand")
                    .hasAnyAuthority(ROLE_MARCHANT, ROLE_ADMIN)

                .requestMatchers(HttpMethod.GET, "/api/statistics/client")
                    .authenticated()

                // ═══════════════════════════════════════════════
                //  MARCHAND + ADMIN
                // ═══════════════════════════════════════════════
                .requestMatchers(HttpMethod.POST, "/api/offres/create")
                    .hasAnyAuthority(ROLE_MARCHANT, ROLE_ADMIN)

                .requestMatchers(HttpMethod.PUT,
                    "/api/offres/update/**",
                    "/api/offres/archive/**",
                    "/api/offres/discount/**"
                ).hasAnyAuthority(ROLE_MARCHANT, ROLE_ADMIN)

                .requestMatchers(HttpMethod.DELETE, "/api/offres/photo/**")
                    .hasAnyAuthority(ROLE_MARCHANT, ROLE_ADMIN)

                .requestMatchers(HttpMethod.POST, "/api/offres/photo/**")
                    .hasAnyAuthority(ROLE_MARCHANT, ROLE_ADMIN)

                .requestMatchers(HttpMethod.GET,
                    "/api/offres/sold-out",
                    "/api/offres/expired",
                    "/api/offres/inactive",
                    "/api/marchand/statistics"
                ).hasAnyAuthority(ROLE_MARCHANT, ROLE_ADMIN)

                .requestMatchers(
                    "/api/roles/marchand/**",
                    "/api/marchand/profile/**"
                ).hasAnyAuthority(ROLE_MARCHANT, ROLE_ADMIN)

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
                ).hasAuthority(ROLE_ADMIN)

                // ═══════════════════════════════════════════════
                //  AUTHENTICATED — token requis (règles générales EN DERNIER)
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
                    "/api/settings/**",
                    "/api/statistics/**"
                ).authenticated()

                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .addFilterBefore(
                jwtFilter,
                UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
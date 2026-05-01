package com.Sallaty.Sallaty.config;

import com.Sallaty.Sallaty.repository.OrdreRepository;
import com.Sallaty.Sallaty.security.CustomUserDetailsService;
import com.Sallaty.Sallaty.security.JwtUtil;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.security.Principal;
import java.util.List;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig
        implements WebSocketMessageBrokerConfigurer {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    private final JwtUtil jwtUtil;
    private final CustomUserDetailsService
        userDetailsService;
    private final OrdreRepository ordreRepository;

    public WebSocketConfig(
            JwtUtil jwtUtil,
            CustomUserDetailsService userDetailsService,
            OrdreRepository ordreRepository) {
        this.jwtUtil            = jwtUtil;
        this.userDetailsService = userDetailsService;
        this.ordreRepository    = ordreRepository;
    }

    // ═══════════════════════════════════════════════
    //  BROKER CONFIG
    // ═══════════════════════════════════════════════
    @Override
    public void configureMessageBroker(
            MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }

    // ═══════════════════════════════════════════════
    //  STOMP ENDPOINT
    //  Flutter connecte → ws://server/ws
    // ═══════════════════════════════════════════════
    @Override
    public void registerStompEndpoints(
            StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");
    }

    // ═══════════════════════════════════════════════
    //  INTERCEPTOR
    // ═══════════════════════════════════════════════
    @Override
    public void configureClientInboundChannel(
            ChannelRegistration registration) {

        registration.interceptors(
            new ChannelInterceptor() {

            @Override
            public Message<?> preSend(
                    Message<?> message,
                    MessageChannel channel) {

                StompHeaderAccessor accessor =
                    StompHeaderAccessor.wrap(message);

                // CONNECT → vérifier JWT
                if (StompCommand.CONNECT.equals(
                        accessor.getCommand())) {
                    authenticateConnect(accessor);
                }

                // SUBSCRIBE → vérifier accès
                if (StompCommand.SUBSCRIBE.equals(
                        accessor.getCommand())) {
                    authorizeSubscribe(accessor);
                }

                return message;
            }
        });
    }

    // ═══════════════════════════════════════════════
    //  authenticateConnect()
    // ═══════════════════════════════════════════════
    private void authenticateConnect(
            StompHeaderAccessor accessor) {

        String auth = getHeader(accessor,
            "Authorization");
        if (auth == null)
            auth = getHeader(accessor,
                "authorization");
        if (auth == null)
            auth = getHeader(accessor, "token");

        if (auth == null ||
            !auth.startsWith("Bearer "))
            throw new AccessDeniedException(
                "Token manquant !");

        String token = auth.substring(7);

        if (!jwtUtil.isTokenValid(token))
            throw new AccessDeniedException(
                "Token invalide !");

        // ➕ Vérifier type ACCESS
        if (jwtUtil.getTokenType(token) !=
                JwtUtil.TokenType.ACCESS)
            throw new AccessDeniedException(
                "Token type invalide !");

        String email = jwtUtil.getEmail(token);
        UserDetails userDetails = userDetailsService
            .loadUserByUsername(email);

        UsernamePasswordAuthenticationToken authToken =
            new UsernamePasswordAuthenticationToken(
                userDetails, null,
                userDetails.getAuthorities());

        accessor.setUser(authToken);
    }

    // ═══════════════════════════════════════════════
    //  authorizeSubscribe()
    // ═══════════════════════════════════════════════
    private void authorizeSubscribe(
            StompHeaderAccessor accessor) {

        String destination =
            accessor.getDestination();
        if (destination == null ||
            destination.isBlank()) return;

        int userId =
            requireAuthenticatedUserId(accessor);

        // /topic/messages/{convId}
        String messagePrefix = "/topic/messages/";
        if (destination.startsWith(messagePrefix)) {
            String conversationId = destination
                .substring(messagePrefix.length());
            if (!isParticipant(
                    userId, conversationId))
                throw new AccessDeniedException(
                    "Accès refusé !");
            return;
        }

        // /topic/location/{ordreId}
        String locationPrefix = "/topic/location/";
        if (destination.startsWith(locationPrefix)) {
            String rawOrdreId = destination
                .substring(locationPrefix.length());
            try {
                int ordreId =
                    Integer.parseInt(rawOrdreId);
                if (!ordreRepository
                        .existsByIdAndParticipant(
                            ordreId, userId))
                    throw new AccessDeniedException(
                        "Accès refusé !");
            } catch (NumberFormatException e) {
                throw new AccessDeniedException(
                    "OrdreId invalide !");
            }
            return;
        }

        // Tout autre /topic → refusé
        if (destination.startsWith("/topic/"))
            throw new AccessDeniedException(
                "Topic non autorisé !");
    }

    // ═══════════════════════════════════════════════
    //  requireAuthenticatedUserId()
    // ═══════════════════════════════════════════════
    private int requireAuthenticatedUserId(
            StompHeaderAccessor accessor) {

        Principal principal = accessor.getUser();

        if (principal instanceof
                UsernamePasswordAuthenticationToken
                    token) {
            Object inner = token.getPrincipal();
            if (inner instanceof
                    UserDetails userDetails) {
                return userDetailsService
                    .getUserIdByEmail(
                        userDetails.getUsername());
            }
        }
        throw new AccessDeniedException(
            "User non authentifié !");
    }

    // ═══════════════════════════════════════════════
    //  isParticipant()
    // ═══════════════════════════════════════════════
    private boolean isParticipant(
            int userId, String conversationId) {

        if (conversationId == null ||
            !conversationId.contains(":"))
            return false;

        String[] parts = conversationId.split(":");
        if (parts.length != 2) return false;

        try {
            int a = Integer.parseInt(parts[0]);
            int b = Integer.parseInt(parts[1]);
            return userId == a || userId == b;
        } catch (NumberFormatException ex) {
            return false;
        }
    }

    // ═══════════════════════════════════════════════
    //  getHeader()
    // ═══════════════════════════════════════════════
    private String getHeader(
            StompHeaderAccessor accessor,
            String name) {

        List<String> values =
            accessor.getNativeHeader(name);
        if (values == null || values.isEmpty())
            return null;
        return values.get(0);
    }
}
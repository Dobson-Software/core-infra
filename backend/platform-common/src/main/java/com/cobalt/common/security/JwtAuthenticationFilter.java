package com.cobalt.common.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;

    public JwtAuthenticationFilter(JwtTokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        String token = extractToken(request);

        if (token != null && tokenProvider.validateToken(token)) {
            Claims claims = tokenProvider.parseToken(token);
            String tokenType = claims.get("type", String.class);

            if ("access".equals(tokenType)) {
                UUID userId = UUID.fromString(claims.getSubject());
                UUID tenantId = UUID.fromString(
                    claims.get("tenantId", String.class)
                );
                String email = claims.get("email", String.class);
                String role = claims.get("role", String.class);

                JwtAuthentication auth = new JwtAuthentication(
                    userId, tenantId, email, role
                );
                SecurityContextHolder.getContext()
                    .setAuthentication(auth);
                MDC.put("tenantId", tenantId.toString());
                MDC.put("userId", userId.toString());
                TenantContext.setCurrentTenantId(tenantId);
            }
        }

        try {
            filterChain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }

    private String extractToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (StringUtils.hasText(header)
            && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }
}

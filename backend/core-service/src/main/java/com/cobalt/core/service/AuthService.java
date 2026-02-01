package com.cobalt.core.service;

import com.cobalt.common.exception.AuthenticationException;
import com.cobalt.common.exception.ConflictException;
import com.cobalt.common.security.JwtTokenProvider;
import com.cobalt.core.dto.auth.AuthResponse;
import com.cobalt.core.dto.auth.LoginRequest;
import com.cobalt.core.dto.auth.RefreshRequest;
import com.cobalt.core.dto.auth.RegisterRequest;
import com.cobalt.core.entity.Tenant;
import com.cobalt.core.entity.User;
import com.cobalt.core.repository.TenantRepository;
import com.cobalt.core.repository.UserRepository;
import io.jsonwebtoken.Claims;
import java.util.Locale;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final TenantRepository tenantRepository;
    private final UserRepository userRepository;
    private final JwtTokenProvider tokenProvider;
    private final PasswordEncoder passwordEncoder;

    public AuthService(
        TenantRepository tenantRepository,
        UserRepository userRepository,
        JwtTokenProvider tokenProvider,
        PasswordEncoder passwordEncoder
    ) {
        this.tenantRepository = tenantRepository;
        this.userRepository = userRepository;
        this.tokenProvider = tokenProvider;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.findByEmail(request.email()).isPresent()) {
            throw new ConflictException(
                "User with email " + request.email()
                    + " already exists"
            );
        }

        String slug = generateSlug(request.companyName());
        if (tenantRepository.existsBySlug(slug)) {
            slug = slug + "-" + UUID.randomUUID().toString()
                .substring(0, 8);
        }

        Tenant tenant = new Tenant();
        tenant.setName(request.companyName());
        tenant.setSlug(slug);
        tenant.setSubscriptionPlan("FREE");
        tenant.setActive(true);
        tenant = tenantRepository.save(tenant);

        User user = new User();
        user.setTenantId(tenant.getId());
        user.setEmail(request.email());
        user.setPasswordHash(
            passwordEncoder.encode(request.password())
        );
        user.setFirstName(request.firstName());
        user.setLastName(request.lastName());
        user.setRole("ADMIN");
        user.setActive(true);
        user = userRepository.save(user);

        return buildAuthResponse(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email())
            .orElseThrow(() -> new AuthenticationException(
                "Invalid email or password"
            ));

        if (!user.isActive()) {
            throw new AuthenticationException("Account is disabled");
        }

        if (!passwordEncoder.matches(
            request.password(), user.getPasswordHash()
        )) {
            throw new AuthenticationException(
                "Invalid email or password"
            );
        }

        return buildAuthResponse(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse refresh(RefreshRequest request) {
        String token = request.refreshToken();

        if (!tokenProvider.validateToken(token)) {
            throw new AuthenticationException(
                "Invalid or expired refresh token"
            );
        }

        String tokenType = tokenProvider.getTokenType(token);
        if (!"refresh".equals(tokenType)) {
            throw new AuthenticationException(
                "Token is not a refresh token"
            );
        }

        Claims claims = tokenProvider.parseToken(token);
        UUID userId = UUID.fromString(claims.getSubject());
        UUID tenantId = UUID.fromString(
            claims.get("tenantId", String.class)
        );

        User user = userRepository.findById(userId)
            .orElseThrow(() -> new AuthenticationException(
                "User not found"
            ));

        if (!user.getTenantId().equals(tenantId)) {
            throw new AuthenticationException(
                "Token tenant mismatch"
            );
        }

        if (!user.isActive()) {
            throw new AuthenticationException("Account is disabled");
        }

        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken = tokenProvider.generateAccessToken(
            user.getId(),
            user.getEmail(),
            user.getRole(),
            user.getTenantId()
        );
        String refreshToken = tokenProvider.generateRefreshToken(
            user.getId(),
            user.getTenantId()
        );

        return new AuthResponse(
            accessToken,
            refreshToken,
            tokenProvider.getAccessTokenExpiration(),
            user.getId(),
            user.getEmail(),
            user.getRole(),
            user.getTenantId()
        );
    }

    private String generateSlug(String name) {
        return name.toLowerCase(Locale.ENGLISH)
            .replaceAll("[^a-z0-9\\s-]", "")
            .replaceAll("\\s+", "-")
            .replaceAll("-+", "-")
            .replaceAll("^-|-$", "");
    }
}

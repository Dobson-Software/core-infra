package com.cobalt.common.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cobalt.common.test.TestFixtures;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JwtTokenProviderTest {

    private JwtTokenProvider tokenProvider;

    private static final long ACCESS_TOKEN_EXPIRATION = 3600000L;
    private static final long REFRESH_TOKEN_EXPIRATION = 86400000L;

    @BeforeEach
    void setUp() {
        tokenProvider = new JwtTokenProvider(
            TestFixtures.JWT_SECRET,
            ACCESS_TOKEN_EXPIRATION,
            REFRESH_TOKEN_EXPIRATION
        );
    }

    @Test
    void generateAccessToken_returnsNonNullToken() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        assertThat(token).isNotNull().isNotBlank();
    }

    @Test
    void generateAccessToken_containsCorrectClaims() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();
        String email = "admin@test.com";
        String role = "ADMIN";

        String token = tokenProvider.generateAccessToken(
            userId, email, role, tenantId
        );

        Claims claims = tokenProvider.parseToken(token);
        assertThat(claims.getSubject()).isEqualTo(userId.toString());
        assertThat(claims.get("email", String.class)).isEqualTo(email);
        assertThat(claims.get("role", String.class)).isEqualTo(role);
        assertThat(claims.get("tenantId", String.class))
            .isEqualTo(tenantId.toString());
        assertThat(claims.get("type", String.class)).isEqualTo("access");
    }

    @Test
    void generateAccessToken_setsExpirationInFuture() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        Claims claims = tokenProvider.parseToken(token);
        assertThat(claims.getExpiration()).isInTheFuture();
        assertThat(claims.getIssuedAt()).isInThePast();
    }

    @Test
    void generateRefreshToken_returnsNonNullToken() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateRefreshToken(userId, tenantId);

        assertThat(token).isNotNull().isNotBlank();
    }

    @Test
    void generateRefreshToken_containsCorrectClaims() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateRefreshToken(userId, tenantId);

        Claims claims = tokenProvider.parseToken(token);
        assertThat(claims.getSubject()).isEqualTo(userId.toString());
        assertThat(claims.get("tenantId", String.class))
            .isEqualTo(tenantId.toString());
        assertThat(claims.get("type", String.class)).isEqualTo("refresh");
    }

    @Test
    void validateToken_withValidToken_returnsTrue() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        assertThat(tokenProvider.validateToken(token)).isTrue();
    }

    @Test
    void validateToken_withInvalidToken_returnsFalse() {
        assertThat(tokenProvider.validateToken("invalid.token.here"))
            .isFalse();
    }

    @Test
    void validateToken_withNullToken_returnsFalse() {
        assertThat(tokenProvider.validateToken(null)).isFalse();
    }

    @Test
    void validateToken_withEmptyToken_returnsFalse() {
        assertThat(tokenProvider.validateToken("")).isFalse();
    }

    @Test
    void validateToken_withTamperedToken_returnsFalse() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        // Tamper with the token by changing a character
        String tampered = token.substring(0, token.length() - 5) + "XXXXX";
        assertThat(tokenProvider.validateToken(tampered)).isFalse();
    }

    @Test
    void validateToken_withExpiredToken_returnsFalse() {
        // Create a provider with 0ms expiration
        JwtTokenProvider expiredProvider = new JwtTokenProvider(
            TestFixtures.JWT_SECRET, 0L, 0L
        );

        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = expiredProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        assertThat(expiredProvider.validateToken(token)).isFalse();
    }

    @Test
    void validateToken_withDifferentSecret_returnsFalse() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        // Create a provider with a different secret
        JwtTokenProvider otherProvider = new JwtTokenProvider(
            "YW5vdGhlci1zZWNyZXQta2V5LWZvci10ZXN0aW5nLW11c3QtYmUtYXQtbGVhc3QtMjU2LWJpdHMtbG9uZw==",
            ACCESS_TOKEN_EXPIRATION,
            REFRESH_TOKEN_EXPIRATION
        );

        assertThat(otherProvider.validateToken(token)).isFalse();
    }

    @Test
    void getUserId_extractsUserIdFromToken() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        assertThat(tokenProvider.getUserId(token)).isEqualTo(userId);
    }

    @Test
    void getTenantId_extractsTenantIdFromToken() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        assertThat(tokenProvider.getTenantId(token)).isEqualTo(tenantId);
    }

    @Test
    void getTokenType_returnsAccessForAccessToken() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        assertThat(tokenProvider.getTokenType(token)).isEqualTo("access");
    }

    @Test
    void getTokenType_returnsRefreshForRefreshToken() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = tokenProvider.generateRefreshToken(userId, tenantId);

        assertThat(tokenProvider.getTokenType(token)).isEqualTo("refresh");
    }

    @Test
    void getAccessTokenExpiration_returnsConfiguredValue() {
        assertThat(tokenProvider.getAccessTokenExpiration())
            .isEqualTo(ACCESS_TOKEN_EXPIRATION);
    }

    @Test
    void parseToken_withExpiredToken_throwsExpiredJwtException() {
        JwtTokenProvider expiredProvider = new JwtTokenProvider(
            TestFixtures.JWT_SECRET, 0L, 0L
        );

        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String token = expiredProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );

        assertThatThrownBy(() -> tokenProvider.parseToken(token))
            .isInstanceOf(ExpiredJwtException.class);
    }

    @Test
    void accessAndRefreshTokens_areDifferent() {
        UUID userId = TestFixtures.randomUserId();
        UUID tenantId = TestFixtures.randomTenantId();

        String accessToken = tokenProvider.generateAccessToken(
            userId, "user@test.com", "ADMIN", tenantId
        );
        String refreshToken = tokenProvider.generateRefreshToken(
            userId, tenantId
        );

        assertThat(accessToken).isNotEqualTo(refreshToken);
    }

    @Test
    void generateAccessToken_differentUsers_produceDifferentTokens() {
        UUID tenantId = TestFixtures.randomTenantId();

        String token1 = tokenProvider.generateAccessToken(
            TestFixtures.randomUserId(), "user1@test.com",
            "ADMIN", tenantId
        );
        String token2 = tokenProvider.generateAccessToken(
            TestFixtures.randomUserId(), "user2@test.com",
            "ADMIN", tenantId
        );

        assertThat(token1).isNotEqualTo(token2);
    }
}

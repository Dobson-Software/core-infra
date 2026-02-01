package com.cobalt.core.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cobalt.common.exception.AuthenticationException;
import com.cobalt.common.exception.ConflictException;
import com.cobalt.common.security.JwtTokenProvider;
import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.core.dto.auth.AuthResponse;
import com.cobalt.core.dto.auth.LoginRequest;
import com.cobalt.core.dto.auth.RefreshRequest;
import com.cobalt.core.dto.auth.RegisterRequest;
import com.cobalt.core.entity.Tenant;
import com.cobalt.core.entity.User;
import com.cobalt.core.repository.TenantRepository;
import com.cobalt.core.repository.UserRepository;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@Transactional
class AuthServiceIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TenantRepository tenantRepository;

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        tenantRepository.deleteAll();
    }

    // ---- Register Tests ----

    @Test
    void register_withValidData_createsUserAndTenant() {
        RegisterRequest request = new RegisterRequest(
            "New HVAC Company",
            "newuser@test.com",
            "password123",
            "John",
            "Doe"
        );

        AuthResponse response = authService.register(request);

        assertThat(response.accessToken()).isNotNull().isNotBlank();
        assertThat(response.refreshToken()).isNotNull().isNotBlank();
        assertThat(response.email()).isEqualTo("newuser@test.com");
        assertThat(response.role()).isEqualTo("ADMIN");
        assertThat(response.userId()).isNotNull();
        assertThat(response.tenantId()).isNotNull();
        assertThat(response.expiresIn()).isGreaterThan(0);
    }

    @Test
    void register_createsValidAccessToken() {
        RegisterRequest request = new RegisterRequest(
            "Token Test Co",
            "tokentest@test.com",
            "password123",
            "Jane",
            "Smith"
        );

        AuthResponse response = authService.register(request);

        assertThat(tokenProvider.validateToken(response.accessToken()))
            .isTrue();
        assertThat(tokenProvider.getTokenType(response.accessToken()))
            .isEqualTo("access");
        assertThat(tokenProvider.getUserId(response.accessToken()))
            .isEqualTo(response.userId());
        assertThat(tokenProvider.getTenantId(response.accessToken()))
            .isEqualTo(response.tenantId());
    }

    @Test
    void register_createsValidRefreshToken() {
        RegisterRequest request = new RegisterRequest(
            "Refresh Test Co",
            "refreshtest@test.com",
            "password123",
            "Bob",
            "Jones"
        );

        AuthResponse response = authService.register(request);

        assertThat(tokenProvider.validateToken(response.refreshToken()))
            .isTrue();
        assertThat(tokenProvider.getTokenType(response.refreshToken()))
            .isEqualTo("refresh");
    }

    @Test
    void register_createsTenantWithSlug() {
        RegisterRequest request = new RegisterRequest(
            "Amazing Plumbing LLC",
            "slug@test.com",
            "password123",
            "Test",
            "User"
        );

        AuthResponse response = authService.register(request);

        Tenant tenant = tenantRepository.findById(response.tenantId())
            .orElseThrow();
        assertThat(tenant.getName()).isEqualTo("Amazing Plumbing LLC");
        assertThat(tenant.getSlug()).contains("amazing-plumbing-llc");
        assertThat(tenant.getSubscriptionPlan()).isEqualTo("FREE");
        assertThat(tenant.isActive()).isTrue();
    }

    @Test
    void register_setsUserAsAdmin() {
        RegisterRequest request = new RegisterRequest(
            "Admin Test Co",
            "admintest@test.com",
            "password123",
            "Admin",
            "User"
        );

        AuthResponse response = authService.register(request);

        User user = userRepository.findById(response.userId())
            .orElseThrow();
        assertThat(user.getRole()).isEqualTo("ADMIN");
        assertThat(user.isActive()).isTrue();
        assertThat(user.getTenantId()).isEqualTo(response.tenantId());
    }

    @Test
    void register_hashesPassword() {
        RegisterRequest request = new RegisterRequest(
            "Password Test Co",
            "pwtest@test.com",
            "password123",
            "Test",
            "User"
        );

        AuthResponse response = authService.register(request);

        User user = userRepository.findById(response.userId())
            .orElseThrow();
        assertThat(user.getPasswordHash()).isNotEqualTo("password123");
        assertThat(
            passwordEncoder.matches("password123", user.getPasswordHash())
        ).isTrue();
    }

    @Test
    void register_withDuplicateEmail_throwsConflictException() {
        RegisterRequest first = new RegisterRequest(
            "First Company",
            "duplicate@test.com",
            "password123",
            "First",
            "User"
        );
        authService.register(first);

        RegisterRequest second = new RegisterRequest(
            "Second Company",
            "duplicate@test.com",
            "password123",
            "Second",
            "User"
        );

        assertThatThrownBy(() -> authService.register(second))
            .isInstanceOf(ConflictException.class)
            .hasMessageContaining("duplicate@test.com");
    }

    // ---- Login Tests ----

    @Test
    void login_withValidCredentials_returnsAuthResponse() {
        RegisterRequest registerReq = new RegisterRequest(
            "Login Test Co",
            "login@test.com",
            "password123",
            "Test",
            "User"
        );
        authService.register(registerReq);

        LoginRequest loginReq = new LoginRequest(
            "login@test.com", "password123"
        );
        AuthResponse response = authService.login(loginReq);

        assertThat(response.accessToken()).isNotNull().isNotBlank();
        assertThat(response.refreshToken()).isNotNull().isNotBlank();
        assertThat(response.email()).isEqualTo("login@test.com");
        assertThat(response.role()).isEqualTo("ADMIN");
    }

    @Test
    void login_withWrongPassword_throwsAuthenticationException() {
        RegisterRequest registerReq = new RegisterRequest(
            "Wrong PW Co",
            "wrongpw@test.com",
            "password123",
            "Test",
            "User"
        );
        authService.register(registerReq);

        LoginRequest loginReq = new LoginRequest(
            "wrongpw@test.com", "wrongpassword"
        );

        assertThatThrownBy(() -> authService.login(loginReq))
            .isInstanceOf(AuthenticationException.class)
            .hasMessageContaining("Invalid email or password");
    }

    @Test
    void login_withNonExistentEmail_throwsAuthenticationException() {
        LoginRequest loginReq = new LoginRequest(
            "nobody@test.com", "password123"
        );

        assertThatThrownBy(() -> authService.login(loginReq))
            .isInstanceOf(AuthenticationException.class)
            .hasMessageContaining("Invalid email or password");
    }

    @Test
    void login_withDisabledAccount_throwsAuthenticationException() {
        RegisterRequest registerReq = new RegisterRequest(
            "Disabled Co",
            "disabled@test.com",
            "password123",
            "Test",
            "User"
        );
        AuthResponse registered = authService.register(registerReq);

        // Disable the user
        User user = userRepository.findById(registered.userId())
            .orElseThrow();
        user.setActive(false);
        userRepository.save(user);
        userRepository.flush();

        LoginRequest loginReq = new LoginRequest(
            "disabled@test.com", "password123"
        );

        assertThatThrownBy(() -> authService.login(loginReq))
            .isInstanceOf(AuthenticationException.class)
            .hasMessageContaining("Account is disabled");
    }

    // ---- Refresh Tests ----

    @Test
    void refresh_withValidRefreshToken_returnsNewTokens() {
        RegisterRequest registerReq = new RegisterRequest(
            "Refresh Co",
            "refresh@test.com",
            "password123",
            "Test",
            "User"
        );
        AuthResponse registered = authService.register(registerReq);

        RefreshRequest refreshReq = new RefreshRequest(
            registered.refreshToken()
        );
        AuthResponse refreshed = authService.refresh(refreshReq);

        assertThat(refreshed.accessToken()).isNotNull().isNotBlank();
        assertThat(refreshed.refreshToken()).isNotNull().isNotBlank();
        assertThat(refreshed.email()).isEqualTo("refresh@test.com");
        assertThat(refreshed.userId()).isEqualTo(registered.userId());
        assertThat(refreshed.tenantId())
            .isEqualTo(registered.tenantId());
    }

    @Test
    void refresh_withAccessTokenInsteadOfRefresh_throwsAuthException() {
        RegisterRequest registerReq = new RegisterRequest(
            "Wrong Type Co",
            "wrongtype@test.com",
            "password123",
            "Test",
            "User"
        );
        AuthResponse registered = authService.register(registerReq);

        // Try to use access token as refresh token
        RefreshRequest refreshReq = new RefreshRequest(
            registered.accessToken()
        );

        assertThatThrownBy(() -> authService.refresh(refreshReq))
            .isInstanceOf(AuthenticationException.class)
            .hasMessageContaining("not a refresh token");
    }

    @Test
    void refresh_withInvalidToken_throwsAuthenticationException() {
        RefreshRequest refreshReq = new RefreshRequest(
            "invalid.token.string"
        );

        assertThatThrownBy(() -> authService.refresh(refreshReq))
            .isInstanceOf(AuthenticationException.class)
            .hasMessageContaining("Invalid or expired");
    }

    @Test
    void refresh_withExpiredToken_throwsAuthenticationException() {
        // Create a provider with 0ms refresh expiration
        JwtTokenProvider expiredProvider = new JwtTokenProvider(
            "dGVzdC1qd3Qtc2VjcmV0LWtleS1mb3ItY29iYWx0LXBsYXRmb3JtLXRlc3RpbmctMjAyNS1tdXN0LWJlLTI1Ni1iaXRz",
            3600000L,
            0L
        );

        UUID userId = UUID.randomUUID();
        UUID tenantId = UUID.randomUUID();
        String expiredRefresh = expiredProvider.generateRefreshToken(
            userId, tenantId
        );

        RefreshRequest refreshReq = new RefreshRequest(expiredRefresh);

        assertThatThrownBy(() -> authService.refresh(refreshReq))
            .isInstanceOf(AuthenticationException.class);
    }

    @Test
    void refresh_withDisabledUser_throwsAuthenticationException() {
        RegisterRequest registerReq = new RegisterRequest(
            "Disabled Refresh Co",
            "disabledrefresh@test.com",
            "password123",
            "Test",
            "User"
        );
        AuthResponse registered = authService.register(registerReq);

        // Disable the user
        User user = userRepository.findById(registered.userId())
            .orElseThrow();
        user.setActive(false);
        userRepository.save(user);
        userRepository.flush();

        RefreshRequest refreshReq = new RefreshRequest(
            registered.refreshToken()
        );

        assertThatThrownBy(() -> authService.refresh(refreshReq))
            .isInstanceOf(AuthenticationException.class)
            .hasMessageContaining("Account is disabled");
    }

    @Test
    void refresh_withTenantMismatch_throwsAuthenticationException() {
        RegisterRequest registerReq = new RegisterRequest(
            "Mismatch Co",
            "mismatch@test.com",
            "password123",
            "Test",
            "User"
        );
        AuthResponse registered = authService.register(registerReq);

        // Manually change user's tenant_id to create mismatch
        User user = userRepository.findById(registered.userId())
            .orElseThrow();
        Tenant otherTenant = new Tenant();
        otherTenant.setName("Other Tenant");
        otherTenant.setSlug("other-tenant-mismatch");
        otherTenant.setSubscriptionPlan("FREE");
        otherTenant.setActive(true);
        otherTenant = tenantRepository.save(otherTenant);

        user.setTenantId(otherTenant.getId());
        userRepository.save(user);
        userRepository.flush();

        // The refresh token still has the old tenant ID
        RefreshRequest refreshReq = new RefreshRequest(
            registered.refreshToken()
        );

        assertThatThrownBy(() -> authService.refresh(refreshReq))
            .isInstanceOf(AuthenticationException.class)
            .hasMessageContaining("Token tenant mismatch");
    }
}

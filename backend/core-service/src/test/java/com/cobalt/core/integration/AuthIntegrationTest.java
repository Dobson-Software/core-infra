package com.cobalt.core.integration;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.core.dto.auth.LoginRequest;
import com.cobalt.core.dto.auth.RefreshRequest;
import com.cobalt.core.dto.auth.RegisterRequest;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@Testcontainers
class AuthIntegrationTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES =
        new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("cobalt_test")
            .withUsername("cobalt_test")
            .withPassword("cobalt_test");

    @DynamicPropertySource
    static void configureDataSource(
        DynamicPropertyRegistry registry
    ) {
        registry.add(
            "spring.datasource.url", POSTGRES::getJdbcUrl
        );
        registry.add(
            "spring.datasource.username", POSTGRES::getUsername
        );
        registry.add(
            "spring.datasource.password", POSTGRES::getPassword
        );
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void register_withValidData_returns201WithTokens() {
        RegisterRequest request = new RegisterRequest(
            "Test HVAC Co",
            "newuser@test.com",
            "password123",
            "John",
            "Doe"
        );

        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/v1/auth/register", request, Map.class
        );

        assertThat(response.getStatusCode())
            .isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();

        Map<String, Object> data = extractData(response);
        assertThat(data.get("accessToken")).isNotNull();
        assertThat(data.get("refreshToken")).isNotNull();
        assertThat(data.get("email")).isEqualTo("newuser@test.com");
        assertThat(data.get("role")).isEqualTo("ADMIN");
        assertThat(data.get("userId")).isNotNull();
        assertThat(data.get("tenantId")).isNotNull();
    }

    @Test
    void login_withRegisteredUser_returns200WithTokens() {
        // Register a user first
        RegisterRequest registerReq = new RegisterRequest(
            "Login Test Co",
            "logintest@test.com",
            "password123",
            "Login",
            "Tester"
        );
        restTemplate.postForEntity(
            "/api/v1/auth/register", registerReq, Map.class
        );

        LoginRequest request = new LoginRequest(
            "logintest@test.com", "password123"
        );

        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/v1/auth/login", request, Map.class
        );

        assertThat(response.getStatusCode())
            .isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();

        Map<String, Object> data = extractData(response);
        assertThat(data.get("accessToken")).isNotNull();
        assertThat(data.get("refreshToken")).isNotNull();
        assertThat(data.get("email")).isEqualTo("logintest@test.com");
        assertThat(data.get("role")).isEqualTo("ADMIN");
    }

    @Test
    void refresh_withValidToken_returns200WithNewTokens() {
        // Register a user first
        RegisterRequest registerReq = new RegisterRequest(
            "Refresh Test Co",
            "refreshtest@test.com",
            "password123",
            "Refresh",
            "Tester"
        );
        restTemplate.postForEntity(
            "/api/v1/auth/register", registerReq, Map.class
        );

        // Login to get a refresh token
        LoginRequest loginRequest = new LoginRequest(
            "refreshtest@test.com", "password123"
        );
        ResponseEntity<Map> loginResponse =
            restTemplate.postForEntity(
                "/api/v1/auth/login", loginRequest, Map.class
            );

        Map<String, Object> loginData = extractData(loginResponse);
        String refreshToken = (String) loginData.get("refreshToken");

        // Use refresh token
        RefreshRequest refreshRequest =
            new RefreshRequest(refreshToken);
        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/v1/auth/refresh", refreshRequest, Map.class
        );

        assertThat(response.getStatusCode())
            .isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();

        Map<String, Object> data = extractData(response);
        assertThat(data.get("accessToken")).isNotNull();
        assertThat(data.get("refreshToken")).isNotNull();
    }

    @Test
    void login_withBadCredentials_returns401() {
        // Register a user first
        RegisterRequest registerReq = new RegisterRequest(
            "Bad Creds Co",
            "badcreds@test.com",
            "password123",
            "Bad",
            "Creds"
        );
        restTemplate.postForEntity(
            "/api/v1/auth/register", registerReq, Map.class
        );

        LoginRequest request = new LoginRequest(
            "badcreds@test.com", "wrongpassword"
        );

        ResponseEntity<Map> response = restTemplate.postForEntity(
            "/api/v1/auth/login", request, Map.class
        );

        assertThat(response.getStatusCode())
            .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void healthEndpoint_returns200() {
        ResponseEntity<Map> response = restTemplate.getForEntity(
            "/actuator/health", Map.class
        );

        assertThat(response.getStatusCode())
            .isEqualTo(HttpStatus.OK);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> extractData(
        ResponseEntity<Map> response
    ) {
        Map<String, Object> body = response.getBody();
        assertThat(body).isNotNull();
        return (Map<String, Object>) body.get("data");
    }
}

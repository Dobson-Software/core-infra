package com.cobalt.common.security;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.config.RateLimitProperties;
import java.io.IOException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RateLimitFilterIntegrationTest {

    private RateLimitFilter filter;

    @BeforeEach
    void setUp() {
        var properties = new RateLimitProperties(
            new RateLimitProperties.Auth(5, 3),
            new RateLimitProperties.Tenant(1000)
        );
        filter = new RateLimitFilter(properties);
    }

    @Test
    void loginEndpoint_shouldReturn429AfterExceedingLimit() throws Exception {
        String clientIp = "192.168.1.100";

        // First 5 requests should succeed
        for (int i = 0; i < 5; i++) {
            MockHttpServletResponse response = executeLoginRequest(clientIp);
            assertThat(response.getStatus()).isEqualTo(200);
        }

        // 6th request should be rate limited
        MockHttpServletResponse response = executeLoginRequest(clientIp);
        assertThat(response.getStatus()).isEqualTo(429);
        assertThat(response.getHeader("Retry-After")).isEqualTo("60");
        assertThat(response.getContentType()).contains("application/problem+json");
    }

    @Test
    void registerEndpoint_shouldReturn429AfterExceedingLimit() throws Exception {
        String clientIp = "192.168.1.101";

        // First 3 requests should succeed
        for (int i = 0; i < 3; i++) {
            MockHttpServletResponse response = executeRegisterRequest(clientIp);
            assertThat(response.getStatus()).isEqualTo(200);
        }

        // 4th request should be rate limited
        MockHttpServletResponse response = executeRegisterRequest(clientIp);
        assertThat(response.getStatus()).isEqualTo(429);
        assertThat(response.getHeader("Retry-After")).isEqualTo("60");
    }

    @Test
    void differentIps_shouldHaveSeparateLimits() throws Exception {
        // Exhaust limit for IP 1
        for (int i = 0; i < 5; i++) {
            executeLoginRequest("10.0.0.1");
        }
        MockHttpServletResponse blockedResponse = executeLoginRequest("10.0.0.1");
        assertThat(blockedResponse.getStatus()).isEqualTo(429);

        // IP 2 should still be allowed
        MockHttpServletResponse allowedResponse = executeLoginRequest("10.0.0.2");
        assertThat(allowedResponse.getStatus()).isEqualTo(200);
    }

    @Test
    void xForwardedFor_shouldBeUsedAsClientIp() throws Exception {
        String realIp = "203.0.113.50";

        for (int i = 0; i < 5; i++) {
            MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");
            request.addHeader("X-Forwarded-For", realIp + ", 10.0.0.1");
            MockHttpServletResponse response = new MockHttpServletResponse();
            filter.doFilter(request, response, new MockFilterChain());
            assertThat(response.getStatus()).isEqualTo(200);
        }

        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        request.addHeader("X-Forwarded-For", realIp + ", 10.0.0.1");
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        assertThat(response.getStatus()).isEqualTo(429);
    }

    @Test
    void nonAuthEndpoints_shouldNotBeRateLimited() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/jobs");
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        assertThat(response.getStatus()).isEqualTo(200);
    }

    private MockHttpServletResponse executeLoginRequest(String clientIp)
        throws IOException, jakarta.servlet.ServletException {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        request.setRemoteAddr(clientIp);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response;
    }

    private MockHttpServletResponse executeRegisterRequest(String clientIp)
        throws IOException, jakarta.servlet.ServletException {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/register");
        request.setRemoteAddr(clientIp);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response;
    }
}

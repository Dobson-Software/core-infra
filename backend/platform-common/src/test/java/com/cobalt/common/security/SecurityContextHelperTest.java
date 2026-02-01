package com.cobalt.common.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cobalt.common.test.TestFixtures;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.context.SecurityContextHolder;

class SecurityContextHelperTest {

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void getCurrentTenantId_withJwtAuthentication_returnsTenantId() {
        UUID tenantId = TestFixtures.randomTenantId();
        UUID userId = TestFixtures.randomUserId();
        setJwtAuthentication(userId, tenantId, "admin@test.com", "ADMIN");

        UUID result = SecurityContextHelper.getCurrentTenantId();

        assertThat(result).isEqualTo(tenantId);
    }

    @Test
    void getCurrentTenantId_withNoAuthentication_throwsIllegalState() {
        assertThatThrownBy(SecurityContextHelper::getCurrentTenantId)
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("No tenant found");
    }

    @Test
    void getCurrentUserId_withJwtAuthentication_returnsUserId() {
        UUID tenantId = TestFixtures.randomTenantId();
        UUID userId = TestFixtures.randomUserId();
        setJwtAuthentication(userId, tenantId, "admin@test.com", "ADMIN");

        UUID result = SecurityContextHelper.getCurrentUserId();

        assertThat(result).isEqualTo(userId);
    }

    @Test
    void getCurrentUserId_withNoAuthentication_throwsIllegalState() {
        assertThatThrownBy(SecurityContextHelper::getCurrentUserId)
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("No user found");
    }

    @Test
    void getCurrentUserRole_withAdminRole_returnsAdmin() {
        UUID tenantId = TestFixtures.randomTenantId();
        UUID userId = TestFixtures.randomUserId();
        setJwtAuthentication(userId, tenantId, "admin@test.com", "ADMIN");

        String result = SecurityContextHelper.getCurrentUserRole();

        assertThat(result).isEqualTo("ADMIN");
    }

    @Test
    void getCurrentUserRole_withManagerRole_returnsManager() {
        UUID tenantId = TestFixtures.randomTenantId();
        UUID userId = TestFixtures.randomUserId();
        setJwtAuthentication(
            userId, tenantId, "manager@test.com", "MANAGER"
        );

        String result = SecurityContextHelper.getCurrentUserRole();

        assertThat(result).isEqualTo("MANAGER");
    }

    @Test
    void getCurrentUserRole_withTechnicianRole_returnsTechnician() {
        UUID tenantId = TestFixtures.randomTenantId();
        UUID userId = TestFixtures.randomUserId();
        setJwtAuthentication(
            userId, tenantId, "tech@test.com", "TECHNICIAN"
        );

        String result = SecurityContextHelper.getCurrentUserRole();

        assertThat(result).isEqualTo("TECHNICIAN");
    }

    @Test
    void getCurrentUserRole_withNoAuthentication_throwsIllegalState() {
        assertThatThrownBy(SecurityContextHelper::getCurrentUserRole)
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("No role found");
    }

    @Test
    void allMethods_returnCorrectValues_forSameContext() {
        UUID tenantId = TestFixtures.randomTenantId();
        UUID userId = TestFixtures.randomUserId();
        String email = "user@test.com";
        String role = "MANAGER";
        setJwtAuthentication(userId, tenantId, email, role);

        assertThat(SecurityContextHelper.getCurrentTenantId())
            .isEqualTo(tenantId);
        assertThat(SecurityContextHelper.getCurrentUserId())
            .isEqualTo(userId);
        assertThat(SecurityContextHelper.getCurrentUserRole())
            .isEqualTo(role);
    }

    @Test
    void getCurrentTenantId_afterClearingContext_throwsIllegalState() {
        UUID tenantId = TestFixtures.randomTenantId();
        UUID userId = TestFixtures.randomUserId();
        setJwtAuthentication(userId, tenantId, "admin@test.com", "ADMIN");

        // Verify it works initially
        assertThat(SecurityContextHelper.getCurrentTenantId())
            .isEqualTo(tenantId);

        // Clear context
        SecurityContextHolder.clearContext();

        // Verify it fails after clearing
        assertThatThrownBy(SecurityContextHelper::getCurrentTenantId)
            .isInstanceOf(IllegalStateException.class);
    }

    private void setJwtAuthentication(
        UUID userId,
        UUID tenantId,
        String email,
        String role
    ) {
        JwtAuthentication auth = new JwtAuthentication(
            userId, tenantId, email, role
        );
        SecurityContextHolder.getContext().setAuthentication(auth);
    }
}

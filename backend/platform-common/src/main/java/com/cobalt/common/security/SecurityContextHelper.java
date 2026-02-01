package com.cobalt.common.security;

import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class SecurityContextHelper {

    private SecurityContextHelper() {
    }

    public static UUID getCurrentTenantId() {
        Authentication auth = SecurityContextHolder.getContext()
            .getAuthentication();
        if (auth instanceof JwtAuthentication jwtAuth) {
            return jwtAuth.getTenantId();
        }
        throw new IllegalStateException(
            "No tenant found in security context"
        );
    }

    public static UUID getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext()
            .getAuthentication();
        if (auth instanceof JwtAuthentication jwtAuth) {
            return jwtAuth.getUserId();
        }
        throw new IllegalStateException(
            "No user found in security context"
        );
    }

    public static String getCurrentUserRole() {
        Authentication auth = SecurityContextHolder.getContext()
            .getAuthentication();
        if (auth instanceof JwtAuthentication jwtAuth) {
            return jwtAuth.getAuthorities().iterator().next()
                .getAuthority().replace("ROLE_", "");
        }
        throw new IllegalStateException(
            "No role found in security context"
        );
    }
}

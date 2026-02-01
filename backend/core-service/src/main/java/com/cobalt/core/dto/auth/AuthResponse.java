package com.cobalt.core.dto.auth;

import java.util.UUID;

public record AuthResponse(
    String accessToken,
    String refreshToken,
    long expiresIn,
    UUID userId,
    String email,
    String role,
    UUID tenantId
) {
}

package com.cobalt.core.controller;

import com.cobalt.common.dto.ApiResponse;
import com.cobalt.core.dto.auth.AuthResponse;
import com.cobalt.core.dto.auth.LoginRequest;
import com.cobalt.core.dto.auth.RefreshRequest;
import com.cobalt.core.dto.auth.RegisterRequest;
import com.cobalt.core.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
        @Valid @RequestBody RegisterRequest request
    ) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.of(response));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
        @Valid @RequestBody LoginRequest request
    ) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.of(response));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
        @Valid @RequestBody RefreshRequest request
    ) {
        AuthResponse response = authService.refresh(request);
        return ResponseEntity.ok(ApiResponse.of(response));
    }
}

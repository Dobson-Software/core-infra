package com.cobalt.common.exception;

import java.net.URI;
import java.time.Instant;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND, ex.getMessage()
        );
        problem.setTitle("Resource Not Found");
        problem.setType(URI.create("https://cobalt.com/errors/not-found"));
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(BadRequestException.class)
    public ProblemDetail handleBadRequest(BadRequestException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, ex.getMessage()
        );
        problem.setTitle("Bad Request");
        problem.setType(URI.create("https://cobalt.com/errors/bad-request"));
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(AuthenticationException.class)
    public ProblemDetail handleAuthentication(AuthenticationException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.UNAUTHORIZED, ex.getMessage()
        );
        problem.setTitle("Authentication Failed");
        problem.setType(URI.create("https://cobalt.com/errors/unauthorized"));
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(ConflictException.class)
    public ProblemDetail handleConflict(ConflictException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.CONFLICT, ex.getMessage()
        );
        problem.setTitle("Conflict");
        problem.setType(URI.create("https://cobalt.com/errors/conflict"));
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(BusinessRuleException.class)
    public ProblemDetail handleBusinessRule(BusinessRuleException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage()
        );
        problem.setTitle("Business Rule Violation");
        problem.setType(
            URI.create("https://cobalt.com/errors/business-rule")
        );
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(
        MethodArgumentNotValidException ex
    ) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, "Validation failed"
        );
        problem.setTitle("Validation Failed");
        problem.setType(URI.create("https://cobalt.com/errors/validation"));
        problem.setProperty("timestamp", Instant.now());
        var errors = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> new FieldError(e.getField(), e.getDefaultMessage()))
            .toList();
        problem.setProperty("errors", errors);
        return problem;
    }

    @ExceptionHandler(RateLimitExceededException.class)
    public ResponseEntity<ProblemDetail> handleRateLimit(
        RateLimitExceededException ex
    ) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.TOO_MANY_REQUESTS, ex.getMessage()
        );
        problem.setTitle("Too Many Requests");
        problem.setType(URI.create("https://cobalt.com/errors/rate-limit"));
        problem.setProperty("timestamp", Instant.now());
        problem.setProperty("retryAfterSeconds", ex.getRetryAfterSeconds());

        HttpHeaders headers = new HttpHeaders();
        headers.set("Retry-After", String.valueOf(ex.getRetryAfterSeconds()));

        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
            .headers(headers)
            .body(problem);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ProblemDetail handleAccessDenied(AccessDeniedException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.FORBIDDEN, ex.getMessage()
        );
        problem.setTitle("Access Denied");
        problem.setType(URI.create("https://cobalt.com/errors/forbidden"));
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ProblemDetail handleMethodNotSupported(
        HttpRequestMethodNotSupportedException ex
    ) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.METHOD_NOT_ALLOWED, ex.getMessage()
        );
        problem.setTitle("Method Not Allowed");
        problem.setType(
            URI.create("https://cobalt.com/errors/method-not-allowed")
        );
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleGenericException(Exception ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.INTERNAL_SERVER_ERROR,
            "An unexpected error occurred"
        );
        problem.setTitle("Internal Server Error");
        problem.setType(
            URI.create("https://cobalt.com/errors/internal")
        );
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }

    private record FieldError(String field, String message) {
    }
}

package com.cobalt.common.security;

import com.cobalt.common.config.RateLimitProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URI;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private final int loginLimit;
    private final int registerLimit;
    private final ConcurrentMap<String, SlidingWindowCounter> loginCounters = new ConcurrentHashMap<>();
    private final ConcurrentMap<String, SlidingWindowCounter> registerCounters = new ConcurrentHashMap<>();

    public RateLimitFilter(RateLimitProperties properties) {
        this.loginLimit = properties.auth().loginPerMinute();
        this.registerLimit = properties.auth().registerPerMinute();
    }

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        String path = request.getRequestURI();
        String clientIp = resolveClientIp(request);

        if (path.startsWith("/api/v1/auth/login")) {
            if (!tryConsume(loginCounters, clientIp, loginLimit)) {
                writeRateLimitResponse(response);
                return;
            }
        } else if (path.startsWith("/api/v1/auth/register")) {
            if (!tryConsume(registerCounters, clientIp, registerLimit)) {
                writeRateLimitResponse(response);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    @Scheduled(fixedRate = 60000)
    public void evictExpiredEntries() {
        long now = System.currentTimeMillis();
        loginCounters.entrySet().removeIf(
            entry -> entry.getValue().isExpired(now)
        );
        registerCounters.entrySet().removeIf(
            entry -> entry.getValue().isExpired(now)
        );
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return !path.startsWith("/api/v1/auth/login")
            && !path.startsWith("/api/v1/auth/register");
    }

    private boolean tryConsume(
        ConcurrentMap<String, SlidingWindowCounter> counters,
        String key,
        int limit
    ) {
        SlidingWindowCounter counter = counters.computeIfAbsent(
            key, k -> new SlidingWindowCounter(Duration.ofMinutes(1))
        );
        return counter.tryIncrement(limit);
    }

    private String resolveClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private void writeRateLimitResponse(HttpServletResponse response) throws IOException {
        long retryAfter = 60;
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.setHeader("Retry-After", String.valueOf(retryAfter));
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.TOO_MANY_REQUESTS,
            "Rate limit exceeded. Try again later."
        );
        problem.setTitle("Too Many Requests");
        problem.setType(URI.create("https://cobalt.com/errors/rate-limit"));
        problem.setProperty("retryAfterSeconds", retryAfter);
        problem.setProperty("timestamp", Instant.now().toString());
        response.getWriter().write(
            """
            {"type":"%s","title":"%s","status":%d,"detail":"%s","retryAfterSeconds":%d}"""
                .formatted(
                    problem.getType(),
                    problem.getTitle(),
                    problem.getStatus(),
                    problem.getDetail(),
                    retryAfter
                )
        );
    }

    private static class SlidingWindowCounter {

        private final Duration window;
        private long windowStart;
        private int count;

        SlidingWindowCounter(Duration window) {
            this.window = window;
            this.windowStart = System.currentTimeMillis();
            this.count = 0;
        }

        synchronized boolean tryIncrement(int limit) {
            long now = System.currentTimeMillis();
            if (now - windowStart > window.toMillis()) {
                windowStart = now;
                count = 0;
            }
            if (count >= limit) {
                return false;
            }
            count++;
            return true;
        }

        boolean isExpired(long now) {
            return now - windowStart > window.toMillis() * 2;
        }
    }
}

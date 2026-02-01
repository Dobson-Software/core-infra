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
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class TenantRateLimitFilter extends OncePerRequestFilter {

    private final int requestsPerMinute;
    private final ConcurrentMap<UUID, SlidingWindowCounter> counters = new ConcurrentHashMap<>();

    public TenantRateLimitFilter(RateLimitProperties properties) {
        this.requestsPerMinute = properties.tenant().requestsPerMinute();
    }

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        UUID tenantId = resolveTenantId();
        if (tenantId != null) {
            SlidingWindowCounter counter = counters.computeIfAbsent(
                tenantId, k -> new SlidingWindowCounter(Duration.ofMinutes(1))
            );
            if (!counter.tryIncrement(requestsPerMinute)) {
                writeRateLimitResponse(response);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    @Scheduled(fixedRate = 60000)
    public void evictExpiredEntries() {
        long now = System.currentTimeMillis();
        counters.entrySet().removeIf(
            entry -> entry.getValue().isExpired(now)
        );
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth == null || !auth.isAuthenticated()
            || "anonymousUser".equals(auth.getPrincipal());
    }

    private UUID resolveTenantId() {
        return TenantContext.getCurrentTenantId();
    }

    private void writeRateLimitResponse(HttpServletResponse response) throws IOException {
        long retryAfter = 60;
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.setHeader("Retry-After", String.valueOf(retryAfter));
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.TOO_MANY_REQUESTS,
            "Tenant rate limit exceeded. Try again later."
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

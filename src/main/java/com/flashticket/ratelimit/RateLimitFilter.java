package com.flashticket.ratelimit;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Collections;

/**
 * Sliding-window rate limiter backed by a single atomic Redis Lua script
 * (one round trip, no race between check-then-increment). Applied only to
 * purchase-attempt endpoints to stop bots from exhausting inventory before
 * real users can check out.
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private final StringRedisTemplate redisTemplate;
    private final DefaultRedisScript<Long> script;

    @Value("${flashticket.ratelimit.max-purchase-attempts-per-minute}")
    private int maxAttemptsPerMinute;

    private static final long WINDOW_MS = 60_000L;

    public RateLimitFilter(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
        this.script = new DefaultRedisScript<>();
        this.script.setLocation(new ClassPathResource("scripts/sliding_window_rate_limiter.lua"));
        this.script.setResultType(Long.class);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // Only gate purchase-attempt endpoints; everything else passes through.
        return !(request.getRequestURI().startsWith("/api/orders") && "POST".equalsIgnoreCase(request.getMethod()));
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String identity = resolveIdentity(request);
        String key = "ratelimit:purchase:" + identity;

        Long allowed = redisTemplate.execute(
                script,
                Collections.singletonList(key),
                String.valueOf(WINDOW_MS),
                String.valueOf(maxAttemptsPerMinute),
                String.valueOf(System.currentTimeMillis())
        );

        if (allowed != null && allowed == 1L) {
            filterChain.doFilter(request, response);
        } else {
            // HttpServletResponse has no SC_TOO_MANY_REQUESTS constant (429 was
            // added to HTTP after the Servlet API's status constants were fixed),
            // so the literal code is used directly.
            response.setStatus(429);
            response.getWriter().write("Too many purchase attempts. Please slow down.");
            response.getWriter().flush();
        }
    }

    private String resolveIdentity(HttpServletRequest request) {
        // Prefer authenticated principal; fall back to client IP for anonymous/bot traffic.
        if (request.getUserPrincipal() != null) {
            return request.getUserPrincipal().getName();
        }
        String forwarded = request.getHeader("X-Forwarded-For");
        return (forwarded != null && !forwarded.isBlank())
                ? forwarded.split(",")[0].trim()
                : request.getRemoteAddr();
    }
}

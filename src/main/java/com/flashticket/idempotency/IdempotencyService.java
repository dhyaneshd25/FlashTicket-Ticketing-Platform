package com.flashticket.idempotency;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

/**
 * Guards Kafka consumers against duplicate processing. Kafka's at-least-once
 * delivery means retries/rebalances can redeliver the same event; this marks
 * an eventId as processed only *after* the work succeeds, so a mid-failure
 * crash doesn't falsely mark it done.
 */
@Service
public class IdempotencyService {

    private static final String KEY_PREFIX = "processed-event:";
    private static final Duration TTL = Duration.ofHours(24);

    private final StringRedisTemplate redisTemplate;

    public IdempotencyService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public boolean isAlreadyProcessed(String eventId) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(KEY_PREFIX + eventId));
    }

    public void markProcessed(String eventId) {
        redisTemplate.opsForValue().set(KEY_PREFIX + eventId, "1", TTL);
    }
}

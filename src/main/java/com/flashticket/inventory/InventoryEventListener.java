package com.flashticket.inventory;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flashticket.idempotency.IdempotencyService;
import com.flashticket.order.event.OrderCreatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Consumes OrderCreatedEvent to finalize seat allocation in the database
 * once Redis has already confirmed availability. Idempotent: duplicate
 * deliveries (Kafka retries/rebalances) are detected and skipped.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class InventoryEventListener {

    private final IdempotencyService idempotencyService;
    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    @KafkaListener(topics = "${flashticket.kafka.topics.order-created}", groupId = "inventory-module")
    @Transactional
    public void onOrderCreated(String rawPayload) throws Exception {
        OrderCreatedEvent event = objectMapper.readValue(rawPayload, OrderCreatedEvent.class);

        if (idempotencyService.isAlreadyProcessed(event.getEventId())) {
            log.info("Skipping duplicate OrderCreatedEvent id={}", event.getEventId());
            return;
        }

        log.info("Finalizing seat allocation for order={} show={}", event.getOrderId(), event.getShowId());
        jdbcTemplate.update(
                "UPDATE event_shows SET available_seats = available_seats - ? WHERE id = ?",
                event.getSeatQuantity(), event.getShowId()
        );

        idempotencyService.markProcessed(event.getEventId());
    }
}

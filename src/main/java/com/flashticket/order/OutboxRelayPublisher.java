package com.flashticket.order;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * The Outbox relay: polls for PENDING outbox rows and publishes them to
 * Kafka, marking each DISPATCHED on success. This is the simplest version
 * of the pattern (a polling publisher); swap for Debezium/Kafka Connect CDC
 * once volume justifies removing the polling latency and DB read load.
 *
 * Guarantees at-least-once delivery: if the process crashes after the Kafka
 * send but before marking DISPATCHED, the row is republished on the next
 * poll — which is exactly why downstream consumers must be idempotent
 * (see IdempotencyService).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OutboxRelayPublisher {

    private final OutboxEventRepository outboxEventRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${flashticket.kafka.topics.order-created}")
    private String orderCreatedTopic;

    @Scheduled(fixedDelay = 500) // poll twice a second; tune based on Kafka Connect/Debezium availability
    @Transactional
    public void relayPendingEvents() {
        List<OutboxEvent> pending = outboxEventRepository.findTop100ByStatusOrderByCreatedAtAsc(OutboxStatus.PENDING);

        for (OutboxEvent event : pending) {
            try {
                String topic = resolveTopic(event.getEventType());
                kafkaTemplate.send(topic, event.getAggregateId(), event.getPayload()).get();
                event.setStatus(OutboxStatus.DISPATCHED);
                outboxEventRepository.save(event);
            } catch (Exception e) {
                log.error("Failed to relay outbox event {} — will retry on next poll", event.getId(), e);
                event.setStatus(OutboxStatus.FAILED);
                outboxEventRepository.save(event);
            }
        }
    }

    private String resolveTopic(String eventType) {
        return switch (eventType) {
            case "OrderCreatedEvent" -> orderCreatedTopic;
            default -> throw new IllegalArgumentException("No topic mapping for event type: " + eventType);
        };
    }
}

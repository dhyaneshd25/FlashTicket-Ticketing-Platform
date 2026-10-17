package com.flashticket.payment;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flashticket.idempotency.IdempotencyService;
import com.flashticket.order.Order;
import com.flashticket.order.OrderRepository;
import com.flashticket.order.OrderStatus;
import com.flashticket.order.event.OrderCreatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Consumes OrderCreatedEvent, attempts the charge, and publishes
 * PaymentConfirmedEvent for the Notification module to react to. Runs on
 * its own consumer group so it processes independently of the Inventory
 * module's consumer.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PaymentEventListener {

    private final PaymentService paymentService;
    private final OrderRepository orderRepository;
    private final IdempotencyService idempotencyService;
    private final ObjectMapper objectMapper;
    private final KafkaTemplate<String, String> kafkaTemplate;

    @org.springframework.beans.factory.annotation.Value("${flashticket.kafka.topics.payment-confirmed}")
    private String paymentConfirmedTopic;

    @KafkaListener(topics = "${flashticket.kafka.topics.order-created}", groupId = "payment-module")
    @Transactional
    public void onOrderCreated(String rawPayload) throws Exception {
        OrderCreatedEvent event = objectMapper.readValue(rawPayload, OrderCreatedEvent.class);
        String idempotencyKey = "payment-" + event.getEventId();

        if (idempotencyService.isAlreadyProcessed(idempotencyKey)) {
            log.info("Skipping duplicate payment processing for order={}", event.getOrderId());
            return;
        }

        boolean success = paymentService.chargeCustomer(event.getOrderId(), event.getUserId(), event.getTotalAmount());

        Order order = orderRepository.findById(event.getOrderId())
                .orElseThrow(() -> new IllegalStateException("Order not found: " + event.getOrderId()));
        order.setStatus(success ? OrderStatus.CONFIRMED : OrderStatus.PAYMENT_FAILED);
        orderRepository.save(order);

        PaymentConfirmedEvent confirmedEvent = new PaymentConfirmedEvent(
                UUID.randomUUID().toString(), event.getOrderId(), success,
                success ? null : "Payment gateway declined or unavailable"
        );
        kafkaTemplate.send(paymentConfirmedTopic, event.getOrderId().toString(),
                objectMapper.writeValueAsString(confirmedEvent));

        idempotencyService.markProcessed(idempotencyKey);
        log.info("Payment {} for order={}", success ? "succeeded" : "failed", event.getOrderId());
    }
}

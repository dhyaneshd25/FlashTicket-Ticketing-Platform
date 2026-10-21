package com.flashticket.notification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flashticket.idempotency.IdempotencyService;
import com.flashticket.payment.PaymentConfirmedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationEventListener {

    private final NotificationService notificationService;
    private final IdempotencyService idempotencyService;
    private final ObjectMapper objectMapper;

    @KafkaListener(topics = "${flashticket.kafka.topics.payment-confirmed}", groupId = "notification-module")
    public void onPaymentConfirmed(String rawPayload) throws Exception {
        PaymentConfirmedEvent event = objectMapper.readValue(rawPayload, PaymentConfirmedEvent.class);
        String idempotencyKey = "notify-" + event.getEventId();

        if (idempotencyService.isAlreadyProcessed(idempotencyKey)) {
            log.info("Skipping duplicate notification for order={}", event.getOrderId());
            return;
        }

        notificationService.sendOrderConfirmation(event.getOrderId(), event.isSuccessful(), event.getFailureReason());
        idempotencyService.markProcessed(idempotencyKey);
    }
}

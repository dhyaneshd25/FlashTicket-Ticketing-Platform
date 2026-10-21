package com.flashticket.notification;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Stands in for a real email/SMS provider (SES, SendGrid, Twilio, etc.).
 */
@Slf4j
@Service
public class NotificationService {

    public void sendOrderConfirmation(UUID orderId, boolean successful, String failureReason) {
        if (successful) {
            log.info("[EMAIL] Order {} confirmed — sending e-ticket to customer", orderId);
        } else {
            log.info("[EMAIL] Order {} payment failed ({}) — sending failure notice", orderId, failureReason);
        }
    }
}

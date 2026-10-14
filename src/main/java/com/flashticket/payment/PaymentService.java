package com.flashticket.payment;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Stands in for a real payment gateway integration (Stripe, Razorpay, etc.).
 * Wrapped in a Resilience4j circuit breaker so a gateway outage degrades
 * gracefully instead of exhausting the consumer thread pool.
 */
@Slf4j
@Service
public class PaymentService {

    @CircuitBreaker(name = "paymentGateway", fallbackMethod = "chargeFallback")
    public boolean chargeCustomer(UUID orderId, UUID userId, java.math.BigDecimal amount) {
        log.info("Charging user={} amount={} for order={}", userId, amount, orderId);
        // Simulated gateway call — replace with a real client (Stripe, Razorpay, etc.)
        return true;
    }

    private boolean chargeFallback(UUID orderId, UUID userId, java.math.BigDecimal amount, Throwable t) {
        log.error("Payment gateway unavailable for order={}, failing safe", orderId, t);
        return false;
    }
}

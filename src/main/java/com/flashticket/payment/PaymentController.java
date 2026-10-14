package com.flashticket.payment;

import com.flashticket.auth.Role;
import com.flashticket.auth.UserPrincipal;
import com.flashticket.inventory.InventoryService;
import com.flashticket.order.Order;
import com.flashticket.order.OrderRepository;
import com.flashticket.order.OrderStatus;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/payment")
@RequiredArgsConstructor
public class PaymentController {

    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final InventoryService inventoryService;

    @PostMapping("/{orderId}/charge")
    @PreAuthorize("isAuthenticated()")
    @Transactional
    public ResponseEntity<Map<String, Object>> processPayment(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UserPrincipal principal) {

        Order order = orderRepository.findById(orderId)
                .orElse(null);
        if (order == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("success", false, "message", "Order not found"));
        }

        // Verify ownership (owner or admin)
        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals(Role.ADMIN));
        if (!isAdmin && !order.getUserId().equals(principal.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("success", false, "message", "You cannot pay for another user's order"));
        }

        if (order.getStatus() == OrderStatus.CONFIRMED) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "status", "CONFIRMED",
                    "orderId", order.getId().toString(),
                    "message", "Order is already paid and confirmed!"
            ));
        }

        boolean charged = paymentService.chargeCustomer(order.getId(), order.getUserId(), order.getTotalAmount());
        if (charged) {
            order.setStatus(OrderStatus.CONFIRMED);
            orderRepository.save(order);
            log.info("Demo payment successful for order={}, status=CONFIRMED", order.getId());

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "status", "CONFIRMED",
                    "orderId", order.getId().toString(),
                    "totalAmount", order.getTotalAmount(),
                    "message", "Payment charged successfully! Your tickets are confirmed."
            ));
        } else {
            order.setStatus(OrderStatus.PAYMENT_FAILED);
            inventoryService.releaseReservation(order.getShowId(), order.getReservationId());
            orderRepository.save(order);
            log.warn("Demo payment failed for order={}, seats released", order.getId());

            return ResponseEntity.status(HttpStatus.PAYMENT_REQUIRED).body(Map.of(
                    "success", false,
                    "status", "PAYMENT_FAILED",
                    "orderId", order.getId().toString(),
                    "message", "Payment gateway declined the transaction. Reserved seats have been released."
            ));
        }
    }

    @PostMapping("/{orderId}/fail")
    @PreAuthorize("isAuthenticated()")
    @Transactional
    public ResponseEntity<Map<String, Object>> simulateFailure(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UserPrincipal principal) {

        Order order = orderRepository.findById(orderId)
                .orElse(null);
        if (order == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("success", false, "message", "Order not found"));
        }

        order.setStatus(OrderStatus.PAYMENT_FAILED);
        inventoryService.releaseReservation(order.getShowId(), order.getReservationId());
        orderRepository.save(order);

        log.info("Simulated payment failure for order={}. Seats released to inventory.", order.getId());
        return ResponseEntity.ok(Map.of(
                "success", false,
                "status", "PAYMENT_FAILED",
                "orderId", order.getId().toString(),
                "message", "Payment simulated failure: Transaction declined. Seats have been released back to available inventory."
        ));
    }
}

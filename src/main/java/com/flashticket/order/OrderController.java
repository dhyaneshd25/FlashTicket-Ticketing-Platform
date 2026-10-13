package com.flashticket.order;

import com.flashticket.auth.UserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;
    private final OrderRepository orderRepository;

    /**
     * The hot-path checkout endpoint. Rate-limited (see RateLimitFilter) and
     * backed entirely by the Redis reservation gate before anything touches
     * the database — this is what absorbs the flash-sale traffic spike.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('USER', 'ORGANIZER', 'ADMIN')")
    public ResponseEntity<Order> createOrder(
            @Valid @RequestBody CreateOrderRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {

        if (principal == null) {
            log.warn("Unauthorized order attempt: user is not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        UUID effectiveUserId = principal.getId();

        int quantity = (request.getSeatCodes() != null && !request.getSeatCodes().isEmpty())
                ? request.getSeatCodes().size()
                : (request.getSeatQuantity() > 0 ? request.getSeatQuantity() : 1);

        Order order = orderService.reserveAndCreateOrder(
                request.getShowId(), effectiveUserId, quantity, request.getSeatCodes()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(order);
    }

    @GetMapping("/my-orders")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<Order>> getMyOrders(@AuthenticationPrincipal UserPrincipal principal) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(orderRepository.findByUserIdOrderByCreatedAtDesc(principal.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Order> getOrder(@PathVariable UUID id) {
        return orderRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}

package com.flashticket.order;

import com.flashticket.inventory.InventoryService;
import com.flashticket.order.event.OrderCreatedEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Order orchestration. reserveAndCreateOrder() is the hot-path entry point
 * called from the checkout flow: it assumes Redis has ALREADY confirmed a
 * soft seat reservation (see InventoryService), and its only job here is to
 * persist the Order + the OutboxEvent in a single DB transaction.
 *
 * This is the crux of the Transactional Outbox pattern: the event payload
 * never leaves this method as a live Kafka publish. It is written to a table
 * in the same transaction as the Order row, so a crash between "order saved"
 * and "event published" is structurally impossible — the relay (see
 * OutboxRelayPublisher) picks up PENDING rows independently.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OutboxEventRepository outboxEventRepository;
    private final InventoryService inventoryService;
    private final com.flashticket.inventory.EventShowRepository eventShowRepository;
    private final ObjectMapper objectMapper;

    private static final BigDecimal DEFAULT_PRICE_PER_SEAT = new BigDecimal("50.00");

    @Transactional
    public Order reserveAndCreateOrder(UUID showId, UUID userId, int seatQuantity, java.util.List<String> seatCodes) {
        String reservationId;
        int effectiveQuantity;
        if (seatCodes != null && !seatCodes.isEmpty()) {
            effectiveQuantity = seatCodes.size();
            reservationId = inventoryService.reserveSeats(showId, seatCodes, userId);
        } else {
            effectiveQuantity = Math.max(1, seatQuantity);
            reservationId = inventoryService.reserveSeatCount(showId, userId, effectiveQuantity);
        }

        BigDecimal pricePerSeat = eventShowRepository.findById(showId)
                .map(com.flashticket.inventory.EventShow::getPrice)
                .orElse(DEFAULT_PRICE_PER_SEAT);

        Order order = new Order();
        order.setShowId(showId);
        order.setUserId(userId);
        order.setReservationId(reservationId);
        order.setSeatQuantity(effectiveQuantity);
        if (seatCodes != null && !seatCodes.isEmpty()) {
            order.setSeatCodes(String.join(",", seatCodes));
        }
        order.setTotalAmount(pricePerSeat.multiply(BigDecimal.valueOf(effectiveQuantity)));
        order.setStatus(OrderStatus.PENDING_PAYMENT);
        order = orderRepository.save(order);

        publishOrderCreatedOutboxEvent(order);

        log.info("Order {} created (PENDING_PAYMENT) for show={} user={} seats={}",
                order.getId(), showId, userId, order.getSeatCodes() != null ? order.getSeatCodes() : effectiveQuantity);
        return order;
    }

    @Transactional
    public Order reserveAndCreateOrder(UUID showId, UUID userId, int seatQuantity) {
        return reserveAndCreateOrder(showId, userId, seatQuantity, null);
    }


    private void publishOrderCreatedOutboxEvent(Order order) {
        try {
            String eventId = UUID.randomUUID().toString();
            OrderCreatedEvent event = new OrderCreatedEvent(
                    eventId, order.getId(), order.getShowId(), order.getUserId(),
                    order.getSeatQuantity(), order.getTotalAmount()
            );

            OutboxEvent outboxEvent = new OutboxEvent();
            outboxEvent.setAggregateType("Order");
            outboxEvent.setAggregateId(order.getId().toString());
            outboxEvent.setEventType("OrderCreatedEvent");
            outboxEvent.setPayload(objectMapper.writeValueAsString(event));
            outboxEvent.setStatus(OutboxStatus.PENDING);

            outboxEventRepository.save(outboxEvent);
        } catch (Exception e) {
            // Serialization failure here should fail the whole transaction —
            // we never want an Order without its corresponding outbox row.
            throw new IllegalStateException("Failed to write outbox event for order " + order.getId(), e);
        }
    }
}

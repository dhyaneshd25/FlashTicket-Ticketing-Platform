package com.flashticket.order.event;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderCreatedEvent {
    private String eventId;
    private UUID orderId;
    private UUID showId;
    private UUID userId;
    private int seatQuantity;
    private BigDecimal totalAmount;
}

package com.flashticket.payment;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentConfirmedEvent {
    private String eventId;
    private UUID orderId;
    private boolean successful;
    private String failureReason;
}

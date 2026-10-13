package com.flashticket.order;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
public class CreateOrderRequest {

    @NotNull(message = "Show ID is required")
    private UUID showId;

    // Optional in request body; will be extracted from the authenticated JWT principal
    private UUID userId;

    @Min(value = 1, message = "Seat quantity must be at least 1")
    private int seatQuantity = 1;

    // Optional list of specific seat codes chosen from seat matrix (e.g. ["A1", "A2"])
    private List<String> seatCodes;
}

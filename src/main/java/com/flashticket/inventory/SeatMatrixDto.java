package com.flashticket.inventory;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SeatMatrixDto {
    private UUID showId;
    private String showTitle;
    private String venue;
    private int totalSeats;
    private int availableSeats;
    private int bookedSeats;
    private BigDecimal price;
    private List<String> rows;
    private int seatsPerRow;
    private List<SeatDto> seats;
}

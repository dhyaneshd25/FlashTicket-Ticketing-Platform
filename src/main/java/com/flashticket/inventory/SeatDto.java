package com.flashticket.inventory;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SeatDto {
    private String code;     // e.g. "A1", "B5"
    private String row;      // e.g. "A"
    private int number;      // e.g. 1
    private String status;   // "AVAILABLE" or "BOOKED"
    private BigDecimal price;
}

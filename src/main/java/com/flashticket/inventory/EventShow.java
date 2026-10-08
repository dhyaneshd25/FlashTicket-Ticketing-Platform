package com.flashticket.inventory;

import com.flashticket.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "event_shows")
public class EventShow extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private String title;

    private String venue;

    @Column(nullable = false)
    private Instant showTime;

    @Column(nullable = false)
    private int totalSeats;

    @Column(nullable = false)
    private int availableSeats;

    @Column
    private BigDecimal price = new BigDecimal("50.00");

    public BigDecimal getPrice() {
        return price != null ? price : new BigDecimal("50.00");
    }
}

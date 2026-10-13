package com.flashticket.order;

import com.flashticket.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

/**
 * Transactional Outbox row. Written in the SAME database transaction as the
 * Order entity, so either both are committed or neither is — no distributed
 * transaction needed. A separate relay process ships PENDING rows to Kafka
 * and marks them DISPATCHED, giving at-least-once delivery.
 */
@Getter
@Setter
@Entity
@Table(name = "outbox_events")
public class OutboxEvent extends BaseEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private String aggregateType;

    @Column(nullable = false)
    private String aggregateId;

    @Column(nullable = false)
    private String eventType;

    @Lob
    @Column(nullable = false)
    private String payload;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OutboxStatus status = OutboxStatus.PENDING;
}

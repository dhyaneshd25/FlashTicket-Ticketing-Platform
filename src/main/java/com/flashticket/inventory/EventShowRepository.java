package com.flashticket.inventory;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface EventShowRepository extends JpaRepository<EventShow, UUID> {
}

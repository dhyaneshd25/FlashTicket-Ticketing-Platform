package com.flashticket.inventory;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * On startup, seeds Redis's per-show available-seat counters from the
 * database. This is the "source of truth on boot, cache thereafter" split:
 * Postgres owns durable state, Redis owns the hot-path concurrency guard
 * for as long as the app is running.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RedisInventorySeeder {

    private final EventShowRepository eventShowRepository;
    private final InventoryService inventoryService;

    @EventListener(ApplicationReadyEvent.class)
    public void seedOnStartup() {
        try {
            eventShowRepository.findAll().forEach(show -> {
                inventoryService.seedAvailability(show.getId(), show.getAvailableSeats());
                log.info("Seeded Redis availability for show '{}' ({} seats)", show.getTitle(), show.getAvailableSeats());
            });
        } catch (Exception e) {
            log.warn("Could not seed Redis inventory on startup (Redis may be offline): {}", e.getMessage());
        }
    }
}

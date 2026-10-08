package com.flashticket.inventory;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/shows")
@RequiredArgsConstructor
public class InventoryController {

    private final EventShowRepository eventShowRepository;
    private final InventoryService inventoryService;

    @GetMapping
    public ResponseEntity<List<EventShow>> listShows() {
        return ResponseEntity.ok(eventShowRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventShow> getShow(@PathVariable UUID id) {
        return eventShowRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/seats")
    public ResponseEntity<SeatMatrixDto> getShowSeats(@PathVariable UUID id) {
        if (!eventShowRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        SeatMatrixDto seatMatrix = inventoryService.getSeatMatrix(id);
        return ResponseEntity.ok(seatMatrix);
    }


    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'ORGANIZER')")
    public ResponseEntity<EventShow> createShow(@Valid @RequestBody CreateShowRequest request) {
        EventShow show = new EventShow();
        show.setTitle(request.getTitle());
        show.setVenue(request.getVenue());
        show.setShowTime(request.getShowTime());
        show.setTotalSeats(request.getTotalSeats());
        show.setAvailableSeats(request.getTotalSeats());
        if (request.getPrice() != null) {
            show.setPrice(request.getPrice());
        }

        EventShow saved = eventShowRepository.save(show);
        inventoryService.seedAvailability(saved.getId(), saved.getAvailableSeats());

        log.info("Created new show: id={} title='{}' seats={}", saved.getId(), saved.getTitle(), saved.getTotalSeats());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteShow(@PathVariable UUID id) {
        if (!eventShowRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        eventShowRepository.deleteById(id);
        log.info("Deleted show: id={}", id);
        return ResponseEntity.noContent().build();
    }
}

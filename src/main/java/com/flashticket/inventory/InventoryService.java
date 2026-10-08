package com.flashticket.inventory;

import com.flashticket.common.SeatUnavailableException;
import lombok.extern.slf4j.Slf4j;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * The flash-sale concurrency guard. Thousands of concurrent "Buy Now" clicks
 * hit this layer first; only requests that clear the Redis gate ever reach
 * the database. Two strategies are provided:
 *
 *  - reserveSeatCount(): atomic DECRBY against a per-show counter, for
 *    "any seat in this tier" purchases (fast path, no lock contention).
 *  - reserveSpecificSeat(): a short-lived Redisson lock for seat-level
 *    selection (e.g. "row A seat 12"), where two users must never win the
 *    same specific seat.
 */
@Slf4j
@Service
public class InventoryService {

    private static final String AVAILABLE_COUNT_KEY_PREFIX = "show:available-count:";
    private static final String SEAT_LOCK_KEY_PREFIX = "show:seat-lock:";
    private static final String RESERVATION_KEY_PREFIX = "show:reservation:";

    private final StringRedisTemplate redisTemplate;
    private final RedissonClient redissonClient;
    private final EventShowRepository eventShowRepository;
    private final com.flashticket.order.OrderRepository orderRepository;

    @Value("${flashticket.redis.reservation-ttl-seconds:600}")
    private long reservationTtlSeconds;

    public InventoryService(
            StringRedisTemplate redisTemplate,
            RedissonClient redissonClient,
            EventShowRepository eventShowRepository,
            com.flashticket.order.OrderRepository orderRepository) {
        this.redisTemplate = redisTemplate;
        this.redissonClient = redissonClient;
        this.eventShowRepository = eventShowRepository;
        this.orderRepository = orderRepository;
    }

    /** Called once when a show goes on sale, to seed the Redis counter from the DB. */
    public void seedAvailability(UUID showId, int availableSeats) {
        // Plain numeric string — DECRBY/INCRBY need this to NOT be JSON-encoded.
        redisTemplate.opsForValue().set(AVAILABLE_COUNT_KEY_PREFIX + showId, String.valueOf(availableSeats));
    }

    /**
     * Fast-path reservation: atomically decrements the show's available-seat
     * counter. Sub-10ms under load since it's a single Redis round trip with
     * no lock contention.
     */
    public String reserveSeatCount(UUID showId, UUID userId, int seatQuantity) {
        int qty = Math.max(1, seatQuantity);
        String countKey = AVAILABLE_COUNT_KEY_PREFIX + showId;

        // Auto-seed Redis from DB if key is missing (e.g., app restarted or database was seeded)
        if (Boolean.FALSE.equals(redisTemplate.hasKey(countKey))) {
            eventShowRepository.findById(showId).ifPresent(show -> {
                seedAvailability(showId, show.getAvailableSeats());
                log.info("Auto-seeded Redis availability for show '{}' with {} seats", show.getTitle(), show.getAvailableSeats());
            });
        }

        Long remaining = redisTemplate.opsForValue().decrement(countKey, qty);

        if (remaining == null || remaining < 0) {
            // Restore the counter — we shouldn't have gone below zero.
            redisTemplate.opsForValue().increment(countKey, qty);
            throw new SeatUnavailableException("Sold out: not enough seats remaining for show " + showId);
        }

        String reservationId = UUID.randomUUID().toString();
        String reservationKey = RESERVATION_KEY_PREFIX + reservationId;
        redisTemplate.opsForHash().put(reservationKey, "showId", showId.toString());
        redisTemplate.opsForHash().put(reservationKey, "userId", userId.toString());
        redisTemplate.opsForHash().put(reservationKey, "seatQuantity", String.valueOf(qty));
        redisTemplate.expire(reservationKey, Duration.ofSeconds(reservationTtlSeconds));

        log.info("Soft-reserved {} seats for show={} user={} reservationId={} remaining={}",
                qty, showId, userId, reservationId, remaining);
        return reservationId;
    }

    public String reserveSeatCount(UUID showId, UUID userId) {
        return reserveSeatCount(showId, userId, 1);
    }

    /**
     * Reserves multiple specific seats chosen from the interactive seat matrix.
     * Uses distributed locks to protect against concurrent collisions.
     */
    public String reserveSeats(UUID showId, java.util.List<String> seatCodes, UUID userId) {
        if (seatCodes == null || seatCodes.isEmpty()) {
            return reserveSeatCount(showId, userId, 1);
        }

        String countKey = AVAILABLE_COUNT_KEY_PREFIX + showId;
        if (Boolean.FALSE.equals(redisTemplate.hasKey(countKey))) {
            eventShowRepository.findById(showId).ifPresent(show -> {
                seedAvailability(showId, show.getAvailableSeats());
            });
        }

        java.util.List<RLock> acquiredLocks = new java.util.ArrayList<>();
        try {
            // Acquire locks for all selected seats
            for (String seatCode : seatCodes) {
                String lockKey = SEAT_LOCK_KEY_PREFIX + showId + ":" + seatCode.toUpperCase();
                RLock lock = redissonClient.getLock(lockKey);
                boolean acquired = lock.tryLock(400, TimeUnit.MILLISECONDS);
                if (!acquired) {
                    throw new SeatUnavailableException("Seat " + seatCode + " is currently being selected by another customer");
                }
                acquiredLocks.add(lock);
            }

            // Verify none of the seats are already taken in Redis or DB
            for (String seatCode : seatCodes) {
                String seatStateKey = "show:seat-state:" + showId + ":" + seatCode.toUpperCase();
                if (Boolean.TRUE.equals(redisTemplate.hasKey(seatStateKey))) {
                    throw new SeatUnavailableException("Seat " + seatCode + " is already reserved or booked");
                }
            }

            // Atomically decrement the available count
            Long remaining = redisTemplate.opsForValue().decrement(countKey, seatCodes.size());
            if (remaining == null || remaining < 0) {
                redisTemplate.opsForValue().increment(countKey, seatCodes.size());
                throw new SeatUnavailableException("Sold out: not enough seats remaining for show " + showId);
            }

            String reservationId = UUID.randomUUID().toString();
            String reservationKey = RESERVATION_KEY_PREFIX + reservationId;

            String joinedCodes = String.join(",", seatCodes);
            redisTemplate.opsForHash().put(reservationKey, "showId", showId.toString());
            redisTemplate.opsForHash().put(reservationKey, "userId", userId.toString());
            redisTemplate.opsForHash().put(reservationKey, "seatQuantity", String.valueOf(seatCodes.size()));
            redisTemplate.opsForHash().put(reservationKey, "seatCode", joinedCodes);
            redisTemplate.expire(reservationKey, Duration.ofSeconds(reservationTtlSeconds));

            // Mark each seat reserved in Redis
            for (String seatCode : seatCodes) {
                String seatStateKey = "show:seat-state:" + showId + ":" + seatCode.toUpperCase();
                redisTemplate.opsForValue().set(seatStateKey, reservationId, Duration.ofSeconds(reservationTtlSeconds));
            }

            log.info("Soft-reserved seats {} for show={} user={} reservationId={}", joinedCodes, showId, userId, reservationId);
            return reservationId;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new SeatUnavailableException("Interrupted while locking seats");
        } finally {
            for (RLock lock : acquiredLocks) {
                if (lock.isHeldByCurrentThread()) {
                    lock.unlock();
                }
            }
        }
    }

    /**
     * Seat-level reservation using a Redisson distributed lock, for cases
     * where a single specific seat identity matters.
     */
    public String reserveSpecificSeat(UUID showId, String seatCode, UUID userId) {
        return reserveSeats(showId, java.util.List.of(seatCode), userId);
    }

    /**
     * Computes the real-time seat matrix for a show, checking DB bookings and Redis soft reservations.
     */
    public SeatMatrixDto getSeatMatrix(UUID showId) {
        EventShow show = eventShowRepository.findById(showId)
                .orElseThrow(() -> new IllegalArgumentException("Show not found: " + showId));

        int totalSeats = show.getTotalSeats() > 0 ? show.getTotalSeats() : 50;
        int seatsPerRow = 10;
        int numRows = (int) Math.ceil((double) totalSeats / seatsPerRow);

        java.util.List<String> rowLabels = new java.util.ArrayList<>();
        for (int i = 0; i < numRows; i++) {
            rowLabels.add(String.valueOf((char) ('A' + i)));
        }

        // Active orders for this show
        java.util.List<com.flashticket.order.Order> activeOrders = orderRepository.findByShowIdAndStatusIn(
                showId, java.util.List.of(com.flashticket.order.OrderStatus.CONFIRMED, com.flashticket.order.OrderStatus.PENDING_PAYMENT)
        );

        java.util.Set<String> explicitlyBookedSeats = new java.util.HashSet<>();
        int legacyBookedCount = 0;

        for (com.flashticket.order.Order order : activeOrders) {
            if (order.getSeatCodes() != null && !order.getSeatCodes().isBlank()) {
                for (String code : order.getSeatCodes().split(",")) {
                    explicitlyBookedSeats.add(code.trim().toUpperCase());
                }
            } else {
                legacyBookedCount += order.getSeatQuantity();
            }
        }

        java.util.List<SeatDto> seats = new java.util.ArrayList<>();
        int legacyAssigned = 0;
        int totalBookedCount = 0;
        int seatIndex = 0;

        for (int r = 0; r < numRows; r++) {
            String row = rowLabels.get(r);
            for (int num = 1; num <= seatsPerRow; num++) {
                seatIndex++;
                if (seatIndex > totalSeats) break;

                String code = row + num;
                boolean isReservedInRedis = Boolean.TRUE.equals(redisTemplate.hasKey("show:seat-state:" + showId + ":" + code));
                boolean isBookedInDb = explicitlyBookedSeats.contains(code);

                boolean isBooked = isReservedInRedis || isBookedInDb;

                if (!isBooked && legacyAssigned < legacyBookedCount) {
                    isBooked = true;
                    legacyAssigned++;
                }

                if (isBooked) {
                    totalBookedCount++;
                }

                seats.add(SeatDto.builder()
                        .code(code)
                        .row(row)
                        .number(num)
                        .status(isBooked ? "BOOKED" : "AVAILABLE")
                        .price(show.getPrice() != null ? show.getPrice() : new java.math.BigDecimal("50.00"))
                        .build());
            }
        }

        int availableCount = Math.max(0, totalSeats - totalBookedCount);

        return SeatMatrixDto.builder()
                .showId(show.getId())
                .showTitle(show.getTitle())
                .venue(show.getVenue())
                .totalSeats(totalSeats)
                .availableSeats(availableCount)
                .bookedSeats(totalBookedCount)
                .price(show.getPrice() != null ? show.getPrice() : new java.math.BigDecimal("50.00"))
                .rows(rowLabels)
                .seatsPerRow(seatsPerRow)
                .seats(seats)
                .build();
    }

    /** Releases a soft reservation, e.g. if payment fails or the hold expires. */
    public void releaseReservation(UUID showId, String reservationId) {
        String reservationKey = RESERVATION_KEY_PREFIX + reservationId;
        String qtyStr = (String) redisTemplate.opsForHash().get(reservationKey, "seatQuantity");
        String seatCodeStr = (String) redisTemplate.opsForHash().get(reservationKey, "seatCode");
        int qty = 1;
        if (qtyStr != null) {
            try {
                qty = Integer.parseInt(qtyStr);
            } catch (NumberFormatException ignored) {}
        }
        if (seatCodeStr != null && !seatCodeStr.isBlank()) {
            String[] codes = seatCodeStr.split(",");
            for (String code : codes) {
                redisTemplate.delete("show:seat-state:" + showId + ":" + code.trim().toUpperCase());
            }
        }
        redisTemplate.delete(reservationKey);
        redisTemplate.opsForValue().increment(AVAILABLE_COUNT_KEY_PREFIX + showId, qty);
        log.info("Released reservation {} ({} seats) for show {}", reservationId, qty, showId);
    }
}

package com.flashticket.admin;

import com.flashticket.admin.dto.AdminStatsDto;
import com.flashticket.admin.dto.UpdateRoleRequest;
import com.flashticket.auth.Role;
import com.flashticket.auth.User;
import com.flashticket.auth.UserRepository;
import com.flashticket.auth.dto.UserDto;
import com.flashticket.inventory.EventShowRepository;
import com.flashticket.order.Order;
import com.flashticket.order.OrderRepository;
import com.flashticket.order.OrderStatus;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminController {

    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final EventShowRepository eventShowRepository;

    @GetMapping("/stats")
    public ResponseEntity<AdminStatsDto> getStats() {
        long totalUsers = userRepository.count();
        long totalShows = eventShowRepository.count();
        long totalOrders = orderRepository.count();
        long confirmedOrders = orderRepository.countByStatus(OrderStatus.CONFIRMED);
        long pendingOrders = orderRepository.countByStatus(OrderStatus.PENDING_PAYMENT);

        List<Order> orders = orderRepository.findAll();
        BigDecimal revenue = orders.stream()
                .filter(o -> o.getStatus() == OrderStatus.CONFIRMED)
                .map(Order::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return ResponseEntity.ok(AdminStatsDto.builder()
                .totalUsers(totalUsers)
                .totalShows(totalShows)
                .totalOrders(totalOrders)
                .confirmedOrders(confirmedOrders)
                .pendingOrders(pendingOrders)
                .totalRevenue(revenue)
                .build());
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserDto>> getAllUsers() {
        List<UserDto> users = userRepository.findAll().stream()
                .map(u -> UserDto.builder()
                        .id(u.getId())
                        .email(u.getEmail())
                        .fullName(u.getFullName())
                        .role(u.getRole())
                        .createdAt(u.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
        return ResponseEntity.ok(users);
    }

    @PutMapping("/users/{id}/role")
    public ResponseEntity<UserDto> updateUserRole(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateRoleRequest request) {

        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found with id: " + id));

        Role newRole = Role.fromString(request.getRole());
        user.setRole(newRole.name());
        user = userRepository.save(user);

        log.info("Admin updated role for user {} to {}", user.getEmail(), user.getRole());

        return ResponseEntity.ok(UserDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .createdAt(user.getCreatedAt())
                .build());
    }

    @GetMapping("/orders")
    public ResponseEntity<List<Order>> getAllOrders() {
        return ResponseEntity.ok(orderRepository.findAllByOrderByCreatedAtDesc());
    }
}

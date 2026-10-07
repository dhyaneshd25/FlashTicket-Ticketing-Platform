package com.flashticket.admin.dto;

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
public class AdminStatsDto {
    private long totalUsers;
    private long totalShows;
    private long totalOrders;
    private long confirmedOrders;
    private long pendingOrders;
    private BigDecimal totalRevenue;
}

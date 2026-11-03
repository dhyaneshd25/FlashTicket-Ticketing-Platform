package com.flashticket.web;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AdminWebController {

    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public String adminDashboard() {
        return "admin-dashboard";
    }

    @GetMapping("/organizer")
    @PreAuthorize("hasAnyRole('ADMIN', 'ORGANIZER')")
    public String organizerDashboard() {
        return "organizer-dashboard";
    }

    @GetMapping("/my-orders")
    @PreAuthorize("isAuthenticated()")
    public String myOrdersPage() {
        return "my-orders";
    }

    @GetMapping("/simulation")
    @PreAuthorize("hasRole('ADMIN')")
    public String simulationDashboard() {
        return "simulation";
    }
}

package com.flashticket.web;

import com.flashticket.inventory.EventShow;
import com.flashticket.inventory.EventShowRepository;
import com.flashticket.order.Order;
import com.flashticket.order.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class EventPageController {

    private final EventShowRepository eventShowRepository;
    private final OrderRepository orderRepository;

    /** Event detail + "Buy Now" page. The actual purchase is an AJAX call to /api/orders (see checkout.js). */
    @GetMapping("/events/{id}")
    public String eventDetail(@PathVariable UUID id, Model model) {
        EventShow show = eventShowRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Show not found"));
        model.addAttribute("show", show);
        return "event-detail";
    }

    /** Demo payment screen where users can review order total and simulate checkout. */
    @GetMapping("/orders/{id}/payment")
    public String orderPayment(@PathVariable UUID id, Model model) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found"));
        EventShow show = eventShowRepository.findById(order.getShowId()).orElse(null);
        model.addAttribute("order", order);
        model.addAttribute("show", show);
        return "demo-payment";
    }

    /** Post-checkout order status page; polls /api/orders/{id} via JS for live status. */
    @GetMapping("/orders/{id}/status")
    public String orderStatus(@PathVariable UUID id, Model model) {
        model.addAttribute("orderId", id);
        return "order-status";
    }
}

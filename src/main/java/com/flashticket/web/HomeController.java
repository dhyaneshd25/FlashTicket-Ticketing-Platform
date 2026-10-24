package com.flashticket.web;

import com.flashticket.inventory.EventShowRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Serves the JSP-rendered frontend pages. Kept deliberately separate from
 * the /api/** REST controllers: this controller returns view names (JSPs),
 * the REST controllers return JSON — both live in the same module boundary
 * but serve different clients (browser page loads vs. AJAX/fetch calls).
 */
@Controller
@RequiredArgsConstructor
public class HomeController {

    private final EventShowRepository eventShowRepository;

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("shows", eventShowRepository.findAll());
        return "index"; // resolves to /WEB-INF/jsp/index.jsp
    }
}

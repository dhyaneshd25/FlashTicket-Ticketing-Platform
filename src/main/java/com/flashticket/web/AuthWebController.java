package com.flashticket.web;

import com.flashticket.auth.JwtAuthenticationFilter;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class AuthWebController {

    @GetMapping("/login")
    public String loginPage(
            @RequestParam(required = false) String redirect,
            @RequestParam(required = false) String registered,
            @RequestParam(required = false) String loggedOut,
            Model model) {
        model.addAttribute("redirect", redirect != null ? redirect : "");
        model.addAttribute("registered", registered != null);
        model.addAttribute("loggedOut", loggedOut != null);
        return "login";
    }

    @GetMapping("/register")
    public String registerPage(
            @RequestParam(required = false) String redirect,
            Model model) {
        model.addAttribute("redirect", redirect != null ? redirect : "");
        return "register";
    }

    @GetMapping("/logout")
    public String logout(HttpServletResponse response) {
        Cookie cookie = new Cookie(JwtAuthenticationFilter.TOKEN_COOKIE_NAME, "");
        cookie.setPath("/");
        cookie.setMaxAge(0);
        response.addCookie(cookie);
        return "redirect:/login?loggedOut=true";
    }
}

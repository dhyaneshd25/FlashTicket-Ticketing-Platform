package com.flashticket.config;

import com.flashticket.auth.JwtAuthenticationFilter;
import com.flashticket.ratelimit.RateLimitFilter;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
@RequiredArgsConstructor
public class SecurityConfig {

    private final RateLimitFilter rateLimitFilter;
    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint((request, response, authException) -> {
                    if (request.getRequestURI().startsWith("/api/")) {
                        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                        response.setContentType("application/json");
                        response.getWriter().write("{\"status\":401,\"error\":\"Unauthorized\",\"message\":\"Please log in to continue.\"}");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/login?redirect=" + request.getRequestURI());
                    }
                })
                .accessDeniedHandler((request, response, accessDeniedException) -> {
                    if (request.getRequestURI().startsWith("/api/")) {
                        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        response.setContentType("application/json");
                        response.getWriter().write("{\"status\":403,\"error\":\"Forbidden\",\"message\":\"Access denied: insufficient permissions.\"}");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/?error=forbidden");
                    }
                })
            )
            .authorizeHttpRequests(auth -> auth
                // Public views and assets
                .requestMatchers("/", "/events/**", "/login", "/register", "/logout", "/orders/**").permitAll()
                .requestMatchers("/static/**", "/resources/**", "/actuator/health").permitAll()
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/shows/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/orders/**").permitAll()

                // Admin-only endpoints (including Architecture Simulation)
                .requestMatchers("/admin/**", "/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/simulation", "/simulation/**", "/api/simulation/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/shows/**").hasRole("ADMIN")
                .requestMatchers("/actuator/**").hasRole("ADMIN")

                // Organizer + Admin endpoints
                .requestMatchers("/organizer/**").hasAnyRole("ADMIN", "ORGANIZER")
                .requestMatchers(HttpMethod.POST, "/api/shows/**").hasAnyRole("ADMIN", "ORGANIZER")
                .requestMatchers(HttpMethod.PUT, "/api/shows/**").hasAnyRole("ADMIN", "ORGANIZER")

                // User / Customer endpoints
                .requestMatchers("/my-orders").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/orders").hasAnyRole("USER", "ADMIN", "ORGANIZER")
                .requestMatchers(HttpMethod.POST, "/api/payment/**").authenticated()

                // Catch-all for API & other routes
                .requestMatchers("/api/**").authenticated()
                .anyRequest().permitAll()
            )
            .addFilterBefore(rateLimitFilter, UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}

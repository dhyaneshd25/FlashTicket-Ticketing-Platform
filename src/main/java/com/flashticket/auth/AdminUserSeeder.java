package com.flashticket.auth;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
@RequiredArgsConstructor
public class AdminUserSeeder {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void seedInitialUsers() {
        seedUserIfNotExists("admin@flashticket.com", "admin123", "System Administrator", Role.ADMIN);
        seedUserIfNotExists("organizer@flashticket.com", "organizer123", "Event Organizer", Role.ORGANIZER);
        seedUserIfNotExists("promoter@flashticket.com", "promoter123", "Live Nation Promoter", Role.ORGANIZER);
        seedUserIfNotExists("user@flashticket.com", "user123", "Demo Customer", Role.USER);
        seedUserIfNotExists("alice@flashticket.com", "password123", "Alice Johnson", Role.USER);
    }

    private void seedUserIfNotExists(String email, String rawPassword, String fullName, String role) {
        if (!userRepository.existsByEmail(email)) {
            User user = User.builder()
                    .email(email)
                    .password(passwordEncoder.encode(rawPassword))
                    .fullName(fullName)
                    .role(role)
                    .build();
            userRepository.save(user);
            log.info("Seeded default account: email={} role={} (password: {})", email, role, rawPassword);
        }
    }
}

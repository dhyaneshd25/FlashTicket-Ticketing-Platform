package com.flashticket.auth;

import com.flashticket.auth.dto.AuthResponse;
import com.flashticket.auth.dto.LoginRequest;
import com.flashticket.auth.dto.RegisterRequest;
import com.flashticket.auth.dto.UserDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail().toLowerCase().trim())) {
            throw new IllegalArgumentException("An account with this email already exists");
        }

        String assignedRole = Role.USER;
        if (request.getRole() != null && !request.getRole().isBlank()) {
            Role requestedRole = Role.fromString(request.getRole());
            if (requestedRole == Role.ROLE_ADMIN) {
                log.warn("Self-registration as ADMIN rejected for email: {}. Defaulting to ROLE_USER.", request.getEmail());
                assignedRole = Role.USER;
            } else {
                assignedRole = requestedRole.name();
            }
        }

        User user = User.builder()
                .email(request.getEmail().toLowerCase().trim())
                .password(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName().trim())
                .role(assignedRole)
                .build();

        user = userRepository.save(user);
        log.info("Registered new user id={} email={}", user.getId(), user.getEmail());

        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getFullName(), user.getRole());

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String email = request.getEmail().toLowerCase().trim();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        log.info("User logged in id={} email={}", user.getId(), user.getEmail());
        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getFullName(), user.getRole());

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();
    }

    @Transactional(readOnly = true)
    public UserDto getCurrentUser(UserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return UserDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .createdAt(user.getCreatedAt())
                .build();
    }
}

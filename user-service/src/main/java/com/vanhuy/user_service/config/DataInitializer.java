package com.vanhuy.user_service.config;

import com.vanhuy.user_service.model.Role;
import com.vanhuy.user_service.model.User;
import com.vanhuy.user_service.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        createIfMissing("admin", "admin@local.dev", "admin123", Role.ROLE_ADMIN);
        createIfMissing("user", "user@local.dev", "user123", Role.ROLE_USER);
    }

    private void createIfMissing(String username, String email, String rawPassword, Role role) {
        if (userRepository.existsByUsername(username)) {
            return;
        }
        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(rawPassword));
        user.setAddress("Local Dev Address");
        user.setActive(true);
        user.getRoles().add(role.name());
        userRepository.save(user);
        log.info("Seeded local user '{}' with role {}", username, role.name());
    }
}

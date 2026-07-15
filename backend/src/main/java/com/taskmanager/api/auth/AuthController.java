package com.taskmanager.api.auth;

import com.taskmanager.api.user.AppUser;
import com.taskmanager.api.user.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserRepository users;
    private final PasswordEncoder passwords;

    public AuthController(UserRepository users, PasswordEncoder passwords) {
        this.users = users; this.passwords = passwords;
    }

    @PostMapping
    public AuthResponse authenticate(@Valid @RequestBody AuthRequest request) {
        String email = request.email().trim().toLowerCase();
        boolean google = "google-oauth".equals(request.password());
        AppUser user = users.findByEmailIgnoreCase(email).orElse(null);

        if (user == null) {
            if ("signIn".equals(request.mode()) && !google) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account not found");
            }
            user = users.save(new AppUser(request.name().trim(), email, passwords.encode(request.password()), google ? "google" : "password"));
        } else if (!google && !passwords.matches(request.password(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Incorrect password");
        } else if (!request.name().isBlank() && !request.name().equals(user.getName())) {
            user.setName(request.name().trim());
            user = users.save(user);
        }
        return new AuthResponse(user.getId(), user.getName(), user.getEmail(), user.getProvider());
    }

    @GetMapping("/session")
    public AuthResponse session(@RequestParam @Email String email) {
        AppUser user = users.findByEmailIgnoreCase(email)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Session account not found"));
        return new AuthResponse(user.getId(), user.getName(), user.getEmail(), user.getProvider());
    }

    public record AuthRequest(@NotBlank String name, @Email @NotBlank String email,
                              @NotBlank String password, @NotBlank String mode, Instant signedAt) {}
    public record AuthResponse(Long id, String name, String email, String provider) {}
}

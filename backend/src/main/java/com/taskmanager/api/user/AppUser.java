package com.taskmanager.api.user;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "app_users", uniqueConstraints = @UniqueConstraint(columnNames = "email"))
public class AppUser {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false) private String name;
    @Column(nullable = false) private String email;
    @Column(nullable = false) private String passwordHash;
    @Column(nullable = false) private String provider;
    private String profileImageKey;
    @Column(nullable = false) private Instant createdAt = Instant.now();

    protected AppUser() {}
    public AppUser(String name, String email, String passwordHash, String provider) {
        this.name = name; this.email = email; this.passwordHash = passwordHash; this.provider = provider;
    }
    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getEmail() { return email; }
    public String getPasswordHash() { return passwordHash; }
    public String getProvider() { return provider; }
    public String getProfileImageKey() { return profileImageKey; }
    public void setProfileImageKey(String profileImageKey) { this.profileImageKey = profileImageKey; }
}

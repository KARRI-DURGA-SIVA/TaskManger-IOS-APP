package com.taskmanager.api.progress;

import com.taskmanager.api.user.AppUser;
import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "daily_progress", uniqueConstraints =
    @UniqueConstraint(name = "uk_progress_owner_date", columnNames = {"owner_id", "progress_date"}))
public class DailyProgress {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private AppUser owner;
    @Column(nullable = false) private LocalDate progressDate;
    @Column(nullable = false) private int scheduledCount;
    @Column(nullable = false) private int completedCount;
    @Column(nullable = false) private int completionPercent;
    @Column(nullable = false) private int currentStreak;
    @Column(nullable = false) private Instant updatedAt;

    protected DailyProgress() {}
    public Long getId() { return id; }
    public AppUser getOwner() { return owner; }
    public void setOwner(AppUser owner) { this.owner = owner; }
    public LocalDate getProgressDate() { return progressDate; }
    public void setProgressDate(LocalDate progressDate) { this.progressDate = progressDate; }
    public int getScheduledCount() { return scheduledCount; }
    public void setScheduledCount(int scheduledCount) { this.scheduledCount = scheduledCount; }
    public int getCompletedCount() { return completedCount; }
    public void setCompletedCount(int completedCount) { this.completedCount = completedCount; }
    public int getCompletionPercent() { return completionPercent; }
    public void setCompletionPercent(int completionPercent) { this.completionPercent = completionPercent; }
    public int getCurrentStreak() { return currentStreak; }
    public void setCurrentStreak(int currentStreak) { this.currentStreak = currentStreak; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}

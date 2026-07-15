package com.taskmanager.api.planner;

import com.taskmanager.api.user.AppUser;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "planner_entries", indexes = @Index(name = "idx_planner_owner_date", columnList = "owner_id, scheduled_at"))
public class PlannerEntry {
    @Id private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private AppUser owner;
    @Column(nullable = false, length = 500) private String title;
    @Column(length = 6000) private String details;
    @Column(nullable = false, length = 32) private String entryType;
    @Column(nullable = false) private Instant scheduledAt;
    @Column(nullable = false) private boolean complete;
    @Column(nullable = false) private Instant createdAt;

    protected PlannerEntry() {}
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public AppUser getOwner() { return owner; }
    public void setOwner(AppUser owner) { this.owner = owner; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }
    public String getEntryType() { return entryType; }
    public void setEntryType(String entryType) { this.entryType = entryType; }
    public Instant getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(Instant scheduledAt) { this.scheduledAt = scheduledAt; }
    public boolean isComplete() { return complete; }
    public void setComplete(boolean complete) { this.complete = complete; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

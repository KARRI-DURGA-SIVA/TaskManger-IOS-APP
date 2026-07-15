package com.taskmanager.api.task;

import com.taskmanager.api.user.AppUser;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "tasks")
public class TaskEntity {
    @Id private UUID id;
    @ManyToOne(optional = false, fetch = FetchType.LAZY) private AppUser owner;
    @Column(nullable = false) private String title;
    @Column(length = 4000) private String description;
    @Column(nullable = false) private Instant dueDate;
    @Column(nullable = false) private String priority;
    @Column(nullable = false) private String category;
    @Column(nullable = false) private boolean reminderEnabled;
    @Column(nullable = false) private boolean complete;
    @Column(nullable = false) private Instant createdAt;
    protected TaskEntity() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public AppUser getOwner() { return owner; }
    public void setOwner(AppUser owner) { this.owner = owner; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Instant getDueDate() { return dueDate; }
    public void setDueDate(Instant dueDate) { this.dueDate = dueDate; }
    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public boolean isReminderEnabled() { return reminderEnabled; }
    public void setReminderEnabled(boolean reminderEnabled) { this.reminderEnabled = reminderEnabled; }
    public boolean isComplete() { return complete; }
    public void setComplete(boolean complete) { this.complete = complete; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

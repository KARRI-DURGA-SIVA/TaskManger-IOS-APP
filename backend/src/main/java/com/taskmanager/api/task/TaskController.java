package com.taskmanager.api.task;

import com.taskmanager.api.user.AppUser;
import com.taskmanager.api.user.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {
    private final TaskRepository tasks;
    private final UserRepository users;
    public TaskController(TaskRepository tasks, UserRepository users) { this.tasks = tasks; this.users = users; }

    @GetMapping
    public List<TaskResponse> list(@RequestParam @Email String email) {
        return tasks.findAllByOwnerEmailOrderByDueDateAsc(email).stream().map(TaskResponse::from).toList();
    }

    @PutMapping("/{id}")
    public TaskResponse upsert(@PathVariable UUID id, @Valid @RequestBody TaskUpsertRequest request) {
        AppUser owner = users.findByEmailIgnoreCase(request.ownerEmail())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sign in before syncing tasks"));
        TaskEntity task = tasks.findById(id).orElseGet(TaskEntity::new);
        if (task.getOwner() != null && !task.getOwner().getEmail().equalsIgnoreCase(owner.getEmail())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Task belongs to another account");
        }
        task.setId(id); task.setOwner(owner); task.setTitle(request.title().trim());
        task.setDescription(request.description()); task.setDueDate(request.dueDate());
        task.setPriority(request.priority()); task.setCategory(request.category());
        task.setReminderEnabled(request.reminderEnabled()); task.setComplete(request.isComplete());
        task.setCreatedAt(request.createdAt());
        return TaskResponse.from(tasks.save(task));
    }

    public record TaskUpsertRequest(@Email @NotBlank String ownerEmail, @NotBlank String title,
        String description, @NotNull Instant dueDate, @NotBlank String priority, @NotBlank String category,
        boolean reminderEnabled, boolean isComplete, @NotNull Instant createdAt) {}
    public record TaskResponse(UUID id, String title, String description, Instant dueDate, String priority,
        String category, boolean reminderEnabled, boolean isComplete, Instant createdAt) {
        static TaskResponse from(TaskEntity task) {
            return new TaskResponse(task.getId(), task.getTitle(), task.getDescription(), task.getDueDate(),
                task.getPriority(), task.getCategory(), task.isReminderEnabled(), task.isComplete(), task.getCreatedAt());
        }
    }
}

package com.taskmanager.api.progress;

import com.taskmanager.api.user.AppUser;
import com.taskmanager.api.user.UserRepository;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/progress")
public class DailyProgressController {
    private final DailyProgressRepository progress;
    private final UserRepository users;
    public DailyProgressController(DailyProgressRepository progress, UserRepository users) {
        this.progress = progress; this.users = users;
    }

    @PutMapping("/daily")
    @Transactional
    public ProgressResponse save(@Valid @RequestBody ProgressRequest request) {
        AppUser owner = users.findByEmailIgnoreCase(request.ownerEmail())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account not found"));
        DailyProgress item = progress.findByOwnerEmailIgnoreCaseAndProgressDate(request.ownerEmail(), request.date())
            .orElseGet(DailyProgress::new);
        item.setOwner(owner); item.setProgressDate(request.date());
        item.setScheduledCount(request.scheduledCount()); item.setCompletedCount(request.completedCount());
        item.setCompletionPercent(request.completionPercent()); item.setCurrentStreak(request.currentStreak());
        item.setUpdatedAt(Instant.now());
        return ProgressResponse.from(progress.save(item));
    }

    @GetMapping("/daily")
    public List<ProgressResponse> range(@RequestParam @Email String email,
        @RequestParam LocalDate start, @RequestParam LocalDate end) {
        return progress.findAllByOwnerEmailIgnoreCaseAndProgressDateBetweenOrderByProgressDate(email, start, end)
            .stream().map(ProgressResponse::from).toList();
    }

    public record ProgressRequest(@Email @NotBlank String ownerEmail, @NotNull LocalDate date,
        @Min(0) int scheduledCount, @Min(0) int completedCount,
        @Min(0) @Max(100) int completionPercent, @Min(0) int currentStreak) {}
    public record ProgressResponse(LocalDate date, int scheduledCount, int completedCount,
        int completionPercent, int currentStreak, Instant updatedAt) {
        static ProgressResponse from(DailyProgress value) {
            return new ProgressResponse(value.getProgressDate(), value.getScheduledCount(),
                value.getCompletedCount(), value.getCompletionPercent(), value.getCurrentStreak(), value.getUpdatedAt());
        }
    }
}

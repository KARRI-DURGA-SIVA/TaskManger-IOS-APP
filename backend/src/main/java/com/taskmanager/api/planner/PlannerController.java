package com.taskmanager.api.planner;

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
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/planner")
public class PlannerController {
    private final PlannerRepository entries;
    private final UserRepository users;
    public PlannerController(PlannerRepository entries, UserRepository users) {
        this.entries = entries; this.users = users;
    }

    @GetMapping
    public List<PlannerResponse> week(@RequestParam @Email String email, @RequestParam Instant weekStart) {
        return entries.findAllByOwnerEmailAndScheduledAtBetweenOrderByScheduledAtAsc(
            email, weekStart, weekStart.plus(7, ChronoUnit.DAYS)
        ).stream().map(PlannerResponse::from).toList();
    }

    @PutMapping("/{id}")
    public PlannerResponse upsert(@PathVariable UUID id, @Valid @RequestBody PlannerRequest request) {
        AppUser owner = users.findByEmailIgnoreCase(request.ownerEmail())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account not found"));
        PlannerEntry entry = entries.findById(id).orElseGet(PlannerEntry::new);
        if (entry.getOwner() != null && !entry.getOwner().getEmail().equalsIgnoreCase(owner.getEmail())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Entry belongs to another account");
        }
        entry.setId(id); entry.setOwner(owner); entry.setTitle(request.title().trim());
        entry.setDetails(request.details() == null ? "" : request.details().trim());
        entry.setEntryType(request.entryType()); entry.setScheduledAt(request.scheduledAt());
        entry.setComplete(request.isComplete()); entry.setCreatedAt(request.createdAt());
        return PlannerResponse.from(entries.save(entry));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id, @RequestParam @Email String email) {
        PlannerEntry entry = entries.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Entry not found"));
        if (!entry.getOwner().getEmail().equalsIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Entry belongs to another account");
        }
        entries.delete(entry);
    }

    public record PlannerRequest(@Email @NotBlank String ownerEmail, @NotBlank String title,
        String details, @NotBlank String entryType, @NotNull Instant scheduledAt,
        boolean isComplete, @NotNull Instant createdAt) {}
    public record PlannerResponse(UUID id, String title, String details, String entryType,
        Instant scheduledAt, boolean isComplete, Instant createdAt) {
        static PlannerResponse from(PlannerEntry entry) {
            return new PlannerResponse(entry.getId(), entry.getTitle(), entry.getDetails(),
                entry.getEntryType(), entry.getScheduledAt(), entry.isComplete(), entry.getCreatedAt());
        }
    }
}

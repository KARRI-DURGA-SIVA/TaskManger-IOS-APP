package com.taskmanager.api.planner;

import com.taskmanager.api.user.AppUser;
import com.taskmanager.api.user.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import jakarta.transaction.Transactional;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
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
    @Transactional
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
    @Transactional
    public void delete(@PathVariable UUID id, @RequestParam @Email String email) {
        PlannerEntry entry = entries.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Entry not found"));
        if (!entry.getOwner().getEmail().equalsIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Entry belongs to another account");
        }
        entries.delete(entry);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
    public ProblemDetail invalidPlannerData(DataIntegrityViolationException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.UNPROCESSABLE_ENTITY,
            "This planner item contains data that cannot be stored. Edit or recreate the item and retry."
        );
        problem.setTitle("Invalid planner item");
        return problem;
    }

    public record PlannerRequest(@Email @NotBlank String ownerEmail,
        @NotBlank @Size(max = 500) String title,
        @Size(max = 6000) String details, @NotBlank @Size(max = 32) String entryType, @NotNull Instant scheduledAt,
        boolean isComplete, @NotNull Instant createdAt) {}
    public record PlannerResponse(UUID id, String title, String details, String entryType,
        Instant scheduledAt, boolean isComplete, Instant createdAt) {
        static PlannerResponse from(PlannerEntry entry) {
            return new PlannerResponse(entry.getId(), entry.getTitle(), entry.getDetails(),
                entry.getEntryType(), entry.getScheduledAt(), entry.isComplete(), entry.getCreatedAt());
        }
    }
}

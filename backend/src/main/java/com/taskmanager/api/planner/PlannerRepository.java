package com.taskmanager.api.planner;

import org.springframework.data.jpa.repository.JpaRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface PlannerRepository extends JpaRepository<PlannerEntry, UUID> {
    List<PlannerEntry> findAllByOwnerEmailAndScheduledAtBetweenOrderByScheduledAtAsc(
        String email, Instant start, Instant end
    );
}

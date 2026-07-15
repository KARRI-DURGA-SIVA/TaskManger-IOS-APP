package com.taskmanager.api.progress;

import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DailyProgressRepository extends JpaRepository<DailyProgress, Long> {
    Optional<DailyProgress> findByOwnerEmailIgnoreCaseAndProgressDate(String email, LocalDate progressDate);
    List<DailyProgress> findAllByOwnerEmailIgnoreCaseAndProgressDateBetweenOrderByProgressDate(
        String email, LocalDate start, LocalDate end
    );
}

package com.cobalt.violations.repository;

import com.cobalt.violations.entity.DobViolation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DobViolationRepository
        extends JpaRepository<DobViolation, UUID> {

    List<DobViolation> findByBin(String bin);

    List<DobViolation> findByBoro(String boro);

    Optional<DobViolation> findByIsnDobBisViol(String isnDobBisViol);
}

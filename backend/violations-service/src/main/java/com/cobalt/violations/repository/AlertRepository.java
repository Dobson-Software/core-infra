package com.cobalt.violations.repository;

import com.cobalt.violations.entity.Alert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AlertRepository
        extends JpaRepository<Alert, UUID> {

    List<Alert> findByTenantId(UUID tenantId);

    List<Alert> findByTenantIdAndReadStatusFalse(UUID tenantId);
}

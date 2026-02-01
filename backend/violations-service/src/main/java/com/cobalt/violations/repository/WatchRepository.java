package com.cobalt.violations.repository;

import com.cobalt.violations.entity.Watch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface WatchRepository
        extends JpaRepository<Watch, UUID> {

    List<Watch> findByTenantId(UUID tenantId);

    List<Watch> findByTenantIdAndActiveTrue(UUID tenantId);
}

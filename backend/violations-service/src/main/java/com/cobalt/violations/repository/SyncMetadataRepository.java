package com.cobalt.violations.repository;

import com.cobalt.violations.entity.SyncMetadata;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SyncMetadataRepository
        extends JpaRepository<SyncMetadata, UUID> {

    Optional<SyncMetadata> findTopByTenantIdOrderByCreatedAtDesc(UUID tenantId);

    Optional<SyncMetadata> findTopByOrderByCreatedAtDesc();
}

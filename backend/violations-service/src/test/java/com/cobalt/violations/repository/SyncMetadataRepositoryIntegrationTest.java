package com.cobalt.violations.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.common.test.TestFixtures;
import com.cobalt.violations.entity.SyncMetadata;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@Transactional
class SyncMetadataRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private SyncMetadataRepository syncMetadataRepository;

    private UUID tenantId1;
    private UUID tenantId2;

    @BeforeEach
    void setUp() {
        syncMetadataRepository.deleteAll();
        tenantId1 = TestFixtures.randomTenantId();
        tenantId2 = TestFixtures.randomTenantId();
    }

    @Test
    void save_withValidMetadata_persistsAndGeneratesId() {
        SyncMetadata metadata = createSyncMetadata(tenantId1, "IDLE");

        SyncMetadata saved = syncMetadataRepository.save(metadata);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getTenantId()).isEqualTo(tenantId1);
        assertThat(saved.getStatus()).isEqualTo("IDLE");
        assertThat(saved.getRecordsProcessed()).isEqualTo(0);
        assertThat(saved.getRecordsInserted()).isEqualTo(0);
        assertThat(saved.getRecordsUpdated()).isEqualTo(0);
        assertThat(saved.getCreatedAt()).isNotNull();
    }

    @Test
    void save_withRunningSync_tracksStartTime() {
        SyncMetadata metadata = createSyncMetadata(
            tenantId1, "RUNNING"
        );
        metadata.setStartedAt(LocalDateTime.now());

        SyncMetadata saved = syncMetadataRepository.save(metadata);

        assertThat(saved.getStartedAt()).isNotNull();
        assertThat(saved.getCompletedAt()).isNull();
    }

    @Test
    void save_withCompletedSync_tracksAllFields() {
        LocalDateTime startTime = LocalDateTime.now().minusMinutes(5);
        LocalDateTime endTime = LocalDateTime.now();

        SyncMetadata metadata = createSyncMetadata(
            tenantId1, "COMPLETED"
        );
        metadata.setStartedAt(startTime);
        metadata.setCompletedAt(endTime);
        metadata.setLastSyncAt(endTime);
        metadata.setRecordsProcessed(1000);
        metadata.setRecordsInserted(800);
        metadata.setRecordsUpdated(200);

        SyncMetadata saved = syncMetadataRepository.save(metadata);

        assertThat(saved.getStatus()).isEqualTo("COMPLETED");
        assertThat(saved.getStartedAt()).isEqualTo(startTime);
        assertThat(saved.getCompletedAt()).isEqualTo(endTime);
        assertThat(saved.getLastSyncAt()).isEqualTo(endTime);
        assertThat(saved.getRecordsProcessed()).isEqualTo(1000);
        assertThat(saved.getRecordsInserted()).isEqualTo(800);
        assertThat(saved.getRecordsUpdated()).isEqualTo(200);
    }

    @Test
    void save_withFailedSync_tracksErrorMessage() {
        SyncMetadata metadata = createSyncMetadata(
            tenantId1, "FAILED"
        );
        metadata.setStartedAt(LocalDateTime.now().minusMinutes(1));
        metadata.setCompletedAt(LocalDateTime.now());
        metadata.setErrorMessage(
            "Connection timeout to Socrata API"
        );
        metadata.setRecordsProcessed(500);
        metadata.setRecordsInserted(500);

        SyncMetadata saved = syncMetadataRepository.save(metadata);

        assertThat(saved.getStatus()).isEqualTo("FAILED");
        assertThat(saved.getErrorMessage())
            .isEqualTo("Connection timeout to Socrata API");
        assertThat(saved.getRecordsProcessed()).isEqualTo(500);
    }

    @Test
    void findTopByTenantIdOrderByCreatedAtDesc_returnsLatestForTenant() {
        // Create older sync record for tenant1
        SyncMetadata older = createSyncMetadata(
            tenantId1, "COMPLETED"
        );
        older.setRecordsProcessed(100);
        syncMetadataRepository.save(older);
        syncMetadataRepository.flush();

        // Create newer sync record for tenant1
        SyncMetadata newer = createSyncMetadata(
            tenantId1, "COMPLETED"
        );
        newer.setRecordsProcessed(200);
        syncMetadataRepository.save(newer);
        syncMetadataRepository.flush();

        // Create record for tenant2
        SyncMetadata tenant2Record = createSyncMetadata(
            tenantId2, "COMPLETED"
        );
        tenant2Record.setRecordsProcessed(999);
        syncMetadataRepository.save(tenant2Record);
        syncMetadataRepository.flush();

        Optional<SyncMetadata> latest =
            syncMetadataRepository
                .findTopByTenantIdOrderByCreatedAtDesc(tenantId1);

        assertThat(latest).isPresent();
        assertThat(latest.get().getRecordsProcessed()).isEqualTo(200);
        assertThat(latest.get().getTenantId()).isEqualTo(tenantId1);
    }

    @Test
    void findTopByTenantIdOrderByCreatedAtDesc_withNoRecords_returnsEmpty() {
        Optional<SyncMetadata> latest =
            syncMetadataRepository
                .findTopByTenantIdOrderByCreatedAtDesc(tenantId1);

        assertThat(latest).isEmpty();
    }

    @Test
    void update_changesStatusFromRunningToCompleted() {
        SyncMetadata metadata = createSyncMetadata(
            tenantId1, "RUNNING"
        );
        metadata.setStartedAt(LocalDateTime.now());
        SyncMetadata saved = syncMetadataRepository.save(metadata);

        saved.setStatus("COMPLETED");
        saved.setCompletedAt(LocalDateTime.now());
        saved.setLastSyncAt(LocalDateTime.now());
        saved.setRecordsProcessed(500);
        saved.setRecordsInserted(300);
        saved.setRecordsUpdated(200);
        SyncMetadata updated = syncMetadataRepository.save(saved);

        assertThat(updated.getStatus()).isEqualTo("COMPLETED");
        assertThat(updated.getCompletedAt()).isNotNull();
        assertThat(updated.getRecordsProcessed()).isEqualTo(500);
    }

    @Test
    void delete_removesExistingMetadata() {
        SyncMetadata saved = syncMetadataRepository.save(
            createSyncMetadata(tenantId1, "IDLE")
        );
        UUID id = saved.getId();

        syncMetadataRepository.deleteById(id);
        syncMetadataRepository.flush();

        assertThat(syncMetadataRepository.findById(id)).isEmpty();
    }

    @Test
    void save_differentTenants_eachGetOwnSyncRecord() {
        SyncMetadata meta1 = createSyncMetadata(
            tenantId1, "COMPLETED"
        );
        meta1.setRecordsProcessed(100);
        syncMetadataRepository.save(meta1);

        SyncMetadata meta2 = createSyncMetadata(
            tenantId2, "COMPLETED"
        );
        meta2.setRecordsProcessed(200);
        syncMetadataRepository.save(meta2);

        assertThat(syncMetadataRepository.findAll()).hasSize(2);
    }

    @Test
    void save_setsCreatedAtAutomatically() {
        SyncMetadata metadata = createSyncMetadata(tenantId1, "IDLE");

        SyncMetadata saved = syncMetadataRepository.save(metadata);

        assertThat(saved.getCreatedAt()).isNotNull();
    }

    private SyncMetadata createSyncMetadata(
        UUID tenantId,
        String status
    ) {
        SyncMetadata metadata = new SyncMetadata();
        metadata.setTenantId(tenantId);
        metadata.setStatus(status);
        return metadata;
    }
}

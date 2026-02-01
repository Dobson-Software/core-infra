package com.cobalt.violations.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.common.test.TestFixtures;
import com.cobalt.violations.entity.Alert;
import com.cobalt.violations.entity.DobViolation;
import com.cobalt.violations.entity.Watch;
import java.time.LocalDateTime;
import java.util.List;
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
class AlertRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private AlertRepository alertRepository;

    @Autowired
    private WatchRepository watchRepository;

    @Autowired
    private DobViolationRepository violationRepository;

    private UUID tenantId1;
    private UUID tenantId2;
    private Watch watch1;
    private Watch watch2;
    private DobViolation violation1;
    private DobViolation violation2;

    @BeforeEach
    void setUp() {
        alertRepository.deleteAll();
        watchRepository.deleteAll();
        violationRepository.deleteAll();

        tenantId1 = TestFixtures.randomTenantId();
        tenantId2 = TestFixtures.randomTenantId();

        // Create watches
        watch1 = createWatch(
            tenantId1, TestFixtures.randomUserId(), "Watch 1",
            "BIN", "1234567"
        );
        watch1 = watchRepository.save(watch1);

        watch2 = createWatch(
            tenantId2, TestFixtures.randomUserId(), "Watch 2",
            "BIN", "7654321"
        );
        watch2 = watchRepository.save(watch2);

        // Create violations
        violation1 = createViolation(
            "V-ALERT-1", "MANHATTAN", "1234567"
        );
        violation1 = violationRepository.save(violation1);

        violation2 = createViolation(
            "V-ALERT-2", "BROOKLYN", "7654321"
        );
        violation2 = violationRepository.save(violation2);
    }

    @Test
    void save_withValidAlert_persistsAndGeneratesId() {
        Alert alert = createAlert(
            tenantId1, watch1.getId(), violation1.getId(), false
        );

        Alert saved = alertRepository.save(alert);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getTenantId()).isEqualTo(tenantId1);
        assertThat(saved.getWatchId()).isEqualTo(watch1.getId());
        assertThat(saved.getViolationId())
            .isEqualTo(violation1.getId());
        assertThat(saved.isReadStatus()).isFalse();
        assertThat(saved.getCreatedAt()).isNotNull();
    }

    @Test
    void findByTenantId_returnsOnlyTenantAlerts() {
        alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation1.getId(), false
            )
        );
        alertRepository.save(
            createAlert(
                tenantId2, watch2.getId(), violation2.getId(), false
            )
        );

        List<Alert> tenant1Alerts =
            alertRepository.findByTenantId(tenantId1);
        List<Alert> tenant2Alerts =
            alertRepository.findByTenantId(tenantId2);

        assertThat(tenant1Alerts).hasSize(1);
        assertThat(tenant1Alerts.get(0).getTenantId())
            .isEqualTo(tenantId1);

        assertThat(tenant2Alerts).hasSize(1);
        assertThat(tenant2Alerts.get(0).getTenantId())
            .isEqualTo(tenantId2);
    }

    @Test
    void findByTenantIdAndReadStatusFalse_returnsOnlyUnread() {
        alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation1.getId(), false
            )
        );

        // Create a second violation for a second alert
        DobViolation violation3 = createViolation(
            "V-ALERT-3", "QUEENS", "5555555"
        );
        violation3 = violationRepository.save(violation3);

        Alert readAlert = createAlert(
            tenantId1, watch1.getId(), violation3.getId(), true
        );
        alertRepository.save(readAlert);

        List<Alert> unreadAlerts =
            alertRepository.findByTenantIdAndReadStatusFalse(tenantId1);

        assertThat(unreadAlerts).hasSize(1);
        assertThat(unreadAlerts.get(0).isReadStatus()).isFalse();
    }

    @Test
    void markAsRead_updatesReadStatus() {
        Alert saved = alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation1.getId(), false
            )
        );

        assertThat(saved.isReadStatus()).isFalse();

        saved.setReadStatus(true);
        Alert updated = alertRepository.save(saved);

        assertThat(updated.isReadStatus()).isTrue();

        // Verify from database
        Alert found =
            alertRepository.findById(updated.getId()).orElseThrow();
        assertThat(found.isReadStatus()).isTrue();
    }

    @Test
    void findByTenantIdAndReadStatusFalse_crossTenantIsolation() {
        alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation1.getId(), false
            )
        );
        alertRepository.save(
            createAlert(
                tenantId2, watch2.getId(), violation2.getId(), false
            )
        );

        List<Alert> tenant1Unread =
            alertRepository.findByTenantIdAndReadStatusFalse(tenantId1);

        assertThat(tenant1Unread).hasSize(1);
        assertThat(tenant1Unread.get(0).getTenantId())
            .isEqualTo(tenantId1);
    }

    @Test
    void findByTenantId_withNoAlerts_returnsEmptyList() {
        UUID emptyTenantId = TestFixtures.randomTenantId();

        List<Alert> alerts =
            alertRepository.findByTenantId(emptyTenantId);

        assertThat(alerts).isEmpty();
    }

    @Test
    void findByTenantIdAndReadStatusFalse_allRead_returnsEmpty() {
        Alert alert = alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation1.getId(), true
            )
        );

        List<Alert> unread =
            alertRepository.findByTenantIdAndReadStatusFalse(tenantId1);

        assertThat(unread).isEmpty();
    }

    @Test
    void delete_removesExistingAlert() {
        Alert saved = alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation1.getId(), false
            )
        );
        UUID id = saved.getId();

        alertRepository.deleteById(id);
        alertRepository.flush();

        assertThat(alertRepository.findById(id)).isEmpty();
    }

    @Test
    void multipleAlerts_forSameWatch_allPersisted() {
        DobViolation violation3 = createViolation(
            "V-MULTI-1", "BRONX", "6666666"
        );
        violation3 = violationRepository.save(violation3);

        DobViolation violation4 = createViolation(
            "V-MULTI-2", "STATEN ISLAND", "7777777"
        );
        violation4 = violationRepository.save(violation4);

        alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation1.getId(), false
            )
        );
        alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation3.getId(), false
            )
        );
        alertRepository.save(
            createAlert(
                tenantId1, watch1.getId(), violation4.getId(), true
            )
        );

        List<Alert> alerts =
            alertRepository.findByTenantId(tenantId1);

        assertThat(alerts).hasSize(3);
    }

    private Alert createAlert(
        UUID tenantId,
        UUID watchId,
        UUID violationId,
        boolean read
    ) {
        Alert alert = new Alert();
        alert.setTenantId(tenantId);
        alert.setWatchId(watchId);
        alert.setViolationId(violationId);
        alert.setReadStatus(read);
        return alert;
    }

    private Watch createWatch(
        UUID tenantId,
        UUID userId,
        String name,
        String filterType,
        String filterValue
    ) {
        Watch watch = new Watch();
        watch.setTenantId(tenantId);
        watch.setUserId(userId);
        watch.setName(name);
        watch.setFilterType(filterType);
        watch.setFilterValue(filterValue);
        watch.setActive(true);
        return watch;
    }

    private DobViolation createViolation(
        String isnDobBisViol,
        String boro,
        String bin
    ) {
        DobViolation violation = new DobViolation();
        violation.setIsnDobBisViol(isnDobBisViol);
        violation.setBoro(boro);
        violation.setBin(bin);
        violation.setSyncedAt(LocalDateTime.now());
        return violation;
    }
}

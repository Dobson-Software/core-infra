package com.cobalt.violations.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.common.test.TestFixtures;
import com.cobalt.violations.entity.Watch;
import java.util.List;
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
class WatchRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private WatchRepository watchRepository;

    private UUID tenantId1;
    private UUID tenantId2;
    private UUID userId1;
    private UUID userId2;

    @BeforeEach
    void setUp() {
        watchRepository.deleteAll();
        tenantId1 = TestFixtures.randomTenantId();
        tenantId2 = TestFixtures.randomTenantId();
        userId1 = TestFixtures.randomUserId();
        userId2 = TestFixtures.randomUserId();
    }

    @Test
    void save_withValidWatch_persistsAndGeneratesId() {
        Watch watch = createWatch(
            tenantId1, userId1, "My BIN Watch", "BIN", "1234567"
        );

        Watch saved = watchRepository.save(watch);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getTenantId()).isEqualTo(tenantId1);
        assertThat(saved.getUserId()).isEqualTo(userId1);
        assertThat(saved.getName()).isEqualTo("My BIN Watch");
        assertThat(saved.getFilterType()).isEqualTo("BIN");
        assertThat(saved.getFilterValue()).isEqualTo("1234567");
        assertThat(saved.isActive()).isTrue();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
    }

    @Test
    void findById_withExistingWatch_returnsWatch() {
        Watch saved = watchRepository.save(
            createWatch(
                tenantId1, userId1, "Test Watch", "ADDRESS",
                "123 Broadway"
            )
        );

        Optional<Watch> found =
            watchRepository.findById(saved.getId());

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Test Watch");
    }

    @Test
    void findById_withNonExistentId_returnsEmpty() {
        Optional<Watch> found =
            watchRepository.findById(UUID.randomUUID());

        assertThat(found).isEmpty();
    }

    @Test
    void findByTenantId_returnsOnlyTenantWatches() {
        watchRepository.save(
            createWatch(tenantId1, userId1, "Watch A", "BIN", "1111111")
        );
        watchRepository.save(
            createWatch(tenantId1, userId2, "Watch B", "BIN", "2222222")
        );
        watchRepository.save(
            createWatch(tenantId2, userId1, "Watch C", "BIN", "3333333")
        );

        List<Watch> tenant1Watches =
            watchRepository.findByTenantId(tenantId1);
        List<Watch> tenant2Watches =
            watchRepository.findByTenantId(tenantId2);

        assertThat(tenant1Watches).hasSize(2);
        assertThat(tenant1Watches)
            .allSatisfy(w ->
                assertThat(w.getTenantId()).isEqualTo(tenantId1)
            );

        assertThat(tenant2Watches).hasSize(1);
        assertThat(tenant2Watches.get(0).getName())
            .isEqualTo("Watch C");
    }

    @Test
    void findByTenantIdAndActiveTrue_returnsOnlyActiveWatches() {
        watchRepository.save(
            createWatch(
                tenantId1, userId1, "Active Watch", "BIN", "1111111"
            )
        );

        Watch inactive = createWatch(
            tenantId1, userId1, "Inactive Watch", "BIN", "2222222"
        );
        inactive.setActive(false);
        watchRepository.save(inactive);

        watchRepository.save(
            createWatch(
                tenantId1, userId2, "Another Active", "ADDRESS",
                "456 Main St"
            )
        );

        List<Watch> activeWatches =
            watchRepository.findByTenantIdAndActiveTrue(tenantId1);

        assertThat(activeWatches).hasSize(2);
        assertThat(activeWatches)
            .allSatisfy(w -> assertThat(w.isActive()).isTrue());
        assertThat(activeWatches)
            .noneMatch(w -> w.getName().equals("Inactive Watch"));
    }

    @Test
    void findByTenantIdAndActiveTrue_crossTenantIsolation() {
        watchRepository.save(
            createWatch(tenantId1, userId1, "T1 Watch", "BIN", "1111111")
        );
        watchRepository.save(
            createWatch(tenantId2, userId1, "T2 Watch", "BIN", "2222222")
        );

        List<Watch> tenant1Active =
            watchRepository.findByTenantIdAndActiveTrue(tenantId1);

        assertThat(tenant1Active).hasSize(1);
        assertThat(tenant1Active.get(0).getName())
            .isEqualTo("T1 Watch");
    }

    @Test
    void update_modifiesExistingWatch() {
        Watch saved = watchRepository.save(
            createWatch(
                tenantId1, userId1, "Original", "BIN", "1111111"
            )
        );

        saved.setName("Updated Name");
        saved.setFilterValue("9999999");
        saved.setActive(false);
        Watch updated = watchRepository.save(saved);

        assertThat(updated.getName()).isEqualTo("Updated Name");
        assertThat(updated.getFilterValue()).isEqualTo("9999999");
        assertThat(updated.isActive()).isFalse();
    }

    @Test
    void delete_removesExistingWatch() {
        Watch saved = watchRepository.save(
            createWatch(
                tenantId1, userId1, "To Delete", "BIN", "1234567"
            )
        );
        UUID id = saved.getId();

        watchRepository.deleteById(id);
        watchRepository.flush();

        assertThat(watchRepository.findById(id)).isEmpty();
    }

    @Test
    void findByTenantId_withNoWatches_returnsEmptyList() {
        UUID emptyTenantId = TestFixtures.randomTenantId();

        List<Watch> watches =
            watchRepository.findByTenantId(emptyTenantId);

        assertThat(watches).isEmpty();
    }

    @Test
    void multipleFilterTypes_allPersisted() {
        watchRepository.save(
            createWatch(tenantId1, userId1, "BIN Watch", "BIN", "1234567")
        );
        watchRepository.save(
            createWatch(
                tenantId1, userId1, "Address Watch", "ADDRESS",
                "123 Broadway, Manhattan"
            )
        );
        watchRepository.save(
            createWatch(
                tenantId1, userId1, "Borough Watch", "BOROUGH",
                "MANHATTAN"
            )
        );

        List<Watch> watches =
            watchRepository.findByTenantId(tenantId1);

        assertThat(watches).hasSize(3);
        assertThat(watches)
            .extracting(Watch::getFilterType)
            .containsExactlyInAnyOrder("BIN", "ADDRESS", "BOROUGH");
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
}

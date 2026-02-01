package com.cobalt.notification.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.common.test.TestFixtures;
import com.cobalt.notification.entity.NotificationPreference;
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
class NotificationPreferenceRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private NotificationPreferenceRepository preferenceRepository;

    private UUID tenantId1;
    private UUID tenantId2;
    private UUID userId1;
    private UUID userId2;

    @BeforeEach
    void setUp() {
        preferenceRepository.deleteAll();
        tenantId1 = TestFixtures.randomTenantId();
        tenantId2 = TestFixtures.randomTenantId();
        userId1 = TestFixtures.randomUserId();
        userId2 = TestFixtures.randomUserId();
    }

    @Test
    void save_withValidPreference_persistsAndGeneratesId() {
        NotificationPreference pref = createPreference(
            tenantId1, userId1, "EMAIL", "JOB_ASSIGNED", true
        );

        NotificationPreference saved = preferenceRepository.save(pref);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getTenantId()).isEqualTo(tenantId1);
        assertThat(saved.getUserId()).isEqualTo(userId1);
        assertThat(saved.getChannel()).isEqualTo("EMAIL");
        assertThat(saved.getNotificationType())
            .isEqualTo("JOB_ASSIGNED");
        assertThat(saved.isEnabled()).isTrue();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
    }

    @Test
    void findByTenantIdAndUserId_returnsUserPreferences() {
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "JOB_ASSIGNED", true
            )
        );
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "SMS", "JOB_ASSIGNED", false
            )
        );
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "INVOICE_CREATED", true
            )
        );
        // Different user same tenant
        preferenceRepository.save(
            createPreference(
                tenantId1, userId2, "EMAIL", "JOB_ASSIGNED", true
            )
        );

        List<NotificationPreference> prefs =
            preferenceRepository.findByTenantIdAndUserId(
                tenantId1, userId1
            );

        assertThat(prefs).hasSize(3);
        assertThat(prefs)
            .allSatisfy(p -> {
                assertThat(p.getTenantId()).isEqualTo(tenantId1);
                assertThat(p.getUserId()).isEqualTo(userId1);
            });
    }

    @Test
    void findByTenantIdAndUserId_crossTenantIsolation() {
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "JOB_ASSIGNED", true
            )
        );
        preferenceRepository.save(
            createPreference(
                tenantId2, userId1, "EMAIL", "JOB_ASSIGNED", true
            )
        );

        List<NotificationPreference> tenant1Prefs =
            preferenceRepository.findByTenantIdAndUserId(
                tenantId1, userId1
            );
        List<NotificationPreference> tenant2Prefs =
            preferenceRepository.findByTenantIdAndUserId(
                tenantId2, userId1
            );

        assertThat(tenant1Prefs).hasSize(1);
        assertThat(tenant1Prefs.get(0).getTenantId())
            .isEqualTo(tenantId1);

        assertThat(tenant2Prefs).hasSize(1);
        assertThat(tenant2Prefs.get(0).getTenantId())
            .isEqualTo(tenantId2);
    }

    @Test
    void findByTenantIdAndUserId_withNoPreferences_returnsEmpty() {
        List<NotificationPreference> prefs =
            preferenceRepository.findByTenantIdAndUserId(
                TestFixtures.randomTenantId(),
                TestFixtures.randomUserId()
            );

        assertThat(prefs).isEmpty();
    }

    @Test
    void update_togglesEnabled() {
        NotificationPreference saved = preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "JOB_ASSIGNED", true
            )
        );

        saved.setEnabled(false);
        NotificationPreference updated =
            preferenceRepository.save(saved);

        assertThat(updated.isEnabled()).isFalse();

        // Toggle back
        updated.setEnabled(true);
        NotificationPreference toggled =
            preferenceRepository.save(updated);
        assertThat(toggled.isEnabled()).isTrue();
    }

    @Test
    void update_changesChannel() {
        NotificationPreference saved = preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "JOB_ASSIGNED", true
            )
        );

        saved.setChannel("SMS");
        NotificationPreference updated =
            preferenceRepository.save(saved);

        assertThat(updated.getChannel()).isEqualTo("SMS");
    }

    @Test
    void delete_removesExistingPreference() {
        NotificationPreference saved = preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "JOB_ASSIGNED", true
            )
        );
        UUID id = saved.getId();

        preferenceRepository.deleteById(id);
        preferenceRepository.flush();

        assertThat(preferenceRepository.findById(id)).isEmpty();
    }

    @Test
    void multiplePreferences_differentTypes_allPersisted() {
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "JOB_ASSIGNED", true
            )
        );
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "INVOICE_CREATED", true
            )
        );
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "EMAIL", "VIOLATION_ALERT", false
            )
        );
        preferenceRepository.save(
            createPreference(
                tenantId1, userId1, "SMS", "JOB_ASSIGNED", true
            )
        );

        List<NotificationPreference> prefs =
            preferenceRepository.findByTenantIdAndUserId(
                tenantId1, userId1
            );

        assertThat(prefs).hasSize(4);
    }

    private NotificationPreference createPreference(
        UUID tenantId,
        UUID userId,
        String channel,
        String notificationType,
        boolean enabled
    ) {
        NotificationPreference pref = new NotificationPreference();
        pref.setTenantId(tenantId);
        pref.setUserId(userId);
        pref.setChannel(channel);
        pref.setNotificationType(notificationType);
        pref.setEnabled(enabled);
        return pref;
    }
}

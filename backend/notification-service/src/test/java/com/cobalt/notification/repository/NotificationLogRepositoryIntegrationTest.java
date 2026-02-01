package com.cobalt.notification.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.common.test.TestFixtures;
import com.cobalt.notification.entity.NotificationLog;
import java.time.LocalDateTime;
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
class NotificationLogRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private NotificationLogRepository logRepository;

    private UUID tenantId1;
    private UUID tenantId2;

    @BeforeEach
    void setUp() {
        logRepository.deleteAll();
        tenantId1 = TestFixtures.randomTenantId();
        tenantId2 = TestFixtures.randomTenantId();
    }

    @Test
    void save_withValidLog_persistsAndGeneratesId() {
        NotificationLog log = createLog(
            tenantId1, "user@test.com", "EMAIL",
            "Welcome", "Welcome body", "PENDING"
        );

        NotificationLog saved = logRepository.save(log);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getTenantId()).isEqualTo(tenantId1);
        assertThat(saved.getRecipient()).isEqualTo("user@test.com");
        assertThat(saved.getChannel()).isEqualTo("EMAIL");
        assertThat(saved.getSubject()).isEqualTo("Welcome");
        assertThat(saved.getBody()).isEqualTo("Welcome body");
        assertThat(saved.getStatus()).isEqualTo("PENDING");
        assertThat(saved.getCreatedAt()).isNotNull();
    }

    @Test
    void findById_withExistingLog_returnsLog() {
        NotificationLog saved = logRepository.save(
            createLog(
                tenantId1, "test@test.com", "SMS",
                null, "Test message", "SENT"
            )
        );

        Optional<NotificationLog> found =
            logRepository.findById(saved.getId());

        assertThat(found).isPresent();
        assertThat(found.get().getRecipient())
            .isEqualTo("test@test.com");
        assertThat(found.get().getChannel()).isEqualTo("SMS");
    }

    @Test
    void findByTenantId_returnsOnlyTenantLogs() {
        logRepository.save(
            createLog(
                tenantId1, "a@t1.com", "EMAIL",
                "Sub A", "Body A", "SENT"
            )
        );
        logRepository.save(
            createLog(
                tenantId1, "b@t1.com", "SMS",
                null, "Body B", "PENDING"
            )
        );
        logRepository.save(
            createLog(
                tenantId2, "c@t2.com", "EMAIL",
                "Sub C", "Body C", "FAILED"
            )
        );

        List<NotificationLog> tenant1Logs =
            logRepository.findByTenantId(tenantId1);
        List<NotificationLog> tenant2Logs =
            logRepository.findByTenantId(tenantId2);

        assertThat(tenant1Logs).hasSize(2);
        assertThat(tenant1Logs)
            .allSatisfy(l ->
                assertThat(l.getTenantId()).isEqualTo(tenantId1)
            );

        assertThat(tenant2Logs).hasSize(1);
        assertThat(tenant2Logs.get(0).getRecipient())
            .isEqualTo("c@t2.com");
    }

    @Test
    void findByTenantId_withNoLogs_returnsEmptyList() {
        UUID emptyTenantId = TestFixtures.randomTenantId();

        List<NotificationLog> logs =
            logRepository.findByTenantId(emptyTenantId);

        assertThat(logs).isEmpty();
    }

    @Test
    void save_withSentStatus_persistsSentAt() {
        NotificationLog log = createLog(
            tenantId1, "sent@test.com", "EMAIL",
            "Sent", "Sent body", "SENT"
        );
        log.setSentAt(LocalDateTime.now());

        NotificationLog saved = logRepository.save(log);

        assertThat(saved.getSentAt()).isNotNull();
    }

    @Test
    void save_withFailedStatus_persistsErrorMessage() {
        NotificationLog log = createLog(
            tenantId1, "failed@test.com", "EMAIL",
            "Failed", "Failed body", "FAILED"
        );
        log.setErrorMessage("SMTP connection refused");

        NotificationLog saved = logRepository.save(log);

        assertThat(saved.getErrorMessage())
            .isEqualTo("SMTP connection refused");
    }

    @Test
    void save_withTemplateId_persistsTemplateId() {
        UUID templateId = UUID.randomUUID();
        NotificationLog log = createLog(
            tenantId1, "template@test.com", "EMAIL",
            "Template", "Template body", "PENDING"
        );
        log.setTemplateId(templateId);

        NotificationLog saved = logRepository.save(log);

        assertThat(saved.getTemplateId()).isEqualTo(templateId);
    }

    @Test
    void tenantIsolation_logsFromDifferentTenants_doNotLeak() {
        logRepository.save(
            createLog(
                tenantId1, "secret@t1.com", "EMAIL",
                "Secret", "Secret data", "SENT"
            )
        );
        logRepository.save(
            createLog(
                tenantId2, "other@t2.com", "EMAIL",
                "Other", "Other data", "SENT"
            )
        );

        List<NotificationLog> tenant1Logs =
            logRepository.findByTenantId(tenantId1);

        assertThat(tenant1Logs).hasSize(1);
        assertThat(tenant1Logs)
            .noneMatch(l -> l.getRecipient().equals("other@t2.com"));
    }

    @Test
    void multipleLogs_forSameRecipient_allPersisted() {
        logRepository.save(
            createLog(
                tenantId1, "multi@test.com", "EMAIL",
                "First", "First body", "SENT"
            )
        );
        logRepository.save(
            createLog(
                tenantId1, "multi@test.com", "EMAIL",
                "Second", "Second body", "SENT"
            )
        );
        logRepository.save(
            createLog(
                tenantId1, "multi@test.com", "SMS",
                null, "SMS body", "PENDING"
            )
        );

        List<NotificationLog> logs =
            logRepository.findByTenantId(tenantId1);

        assertThat(logs).hasSize(3);
    }

    private NotificationLog createLog(
        UUID tenantId,
        String recipient,
        String channel,
        String subject,
        String body,
        String status
    ) {
        NotificationLog log = new NotificationLog();
        log.setTenantId(tenantId);
        log.setRecipient(recipient);
        log.setChannel(channel);
        log.setSubject(subject);
        log.setBody(body);
        log.setStatus(status);
        return log;
    }
}

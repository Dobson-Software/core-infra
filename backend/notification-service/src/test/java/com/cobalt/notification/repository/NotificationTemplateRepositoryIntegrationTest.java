package com.cobalt.notification.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.common.test.TestFixtures;
import com.cobalt.notification.entity.NotificationTemplate;
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
class NotificationTemplateRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private NotificationTemplateRepository templateRepository;

    private UUID tenantId1;
    private UUID tenantId2;

    @BeforeEach
    void setUp() {
        templateRepository.deleteAll();
        tenantId1 = TestFixtures.randomTenantId();
        tenantId2 = TestFixtures.randomTenantId();
    }

    @Test
    void save_withValidTemplate_persistsAndGeneratesId() {
        NotificationTemplate template = createTemplate(
            tenantId1, "Welcome Email", "EMAIL",
            "Welcome to Cobalt", "Hello {{name}}!"
        );

        NotificationTemplate saved = templateRepository.save(template);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getTenantId()).isEqualTo(tenantId1);
        assertThat(saved.getName()).isEqualTo("Welcome Email");
        assertThat(saved.getType()).isEqualTo("EMAIL");
        assertThat(saved.getSubject()).isEqualTo("Welcome to Cobalt");
        assertThat(saved.getBody()).isEqualTo("Hello {{name}}!");
        assertThat(saved.isActive()).isTrue();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
    }

    @Test
    void findById_withExistingTemplate_returnsTemplate() {
        NotificationTemplate saved = templateRepository.save(
            createTemplate(
                tenantId1, "Job Assigned", "EMAIL",
                "New Job", "You have been assigned a job."
            )
        );

        Optional<NotificationTemplate> found =
            templateRepository.findById(saved.getId());

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Job Assigned");
    }

    @Test
    void findById_withNonExistentId_returnsEmpty() {
        Optional<NotificationTemplate> found =
            templateRepository.findById(UUID.randomUUID());

        assertThat(found).isEmpty();
    }

    @Test
    void findByTenantId_returnsOnlyTenantTemplates() {
        templateRepository.save(
            createTemplate(
                tenantId1, "Template A", "EMAIL",
                "Subject A", "Body A"
            )
        );
        templateRepository.save(
            createTemplate(
                tenantId1, "Template B", "SMS",
                null, "SMS body B"
            )
        );
        templateRepository.save(
            createTemplate(
                tenantId2, "Template C", "EMAIL",
                "Subject C", "Body C"
            )
        );

        List<NotificationTemplate> tenant1Templates =
            templateRepository.findByTenantId(tenantId1);
        List<NotificationTemplate> tenant2Templates =
            templateRepository.findByTenantId(tenantId2);

        assertThat(tenant1Templates).hasSize(2);
        assertThat(tenant1Templates)
            .allSatisfy(t ->
                assertThat(t.getTenantId()).isEqualTo(tenantId1)
            );

        assertThat(tenant2Templates).hasSize(1);
        assertThat(tenant2Templates.get(0).getName())
            .isEqualTo("Template C");
    }

    @Test
    void findByTenantIdAndType_filtersCorrectly() {
        templateRepository.save(
            createTemplate(
                tenantId1, "Email 1", "EMAIL",
                "Subject 1", "Body 1"
            )
        );
        templateRepository.save(
            createTemplate(
                tenantId1, "SMS 1", "SMS",
                null, "SMS Body"
            )
        );
        templateRepository.save(
            createTemplate(
                tenantId1, "Email 2", "EMAIL",
                "Subject 2", "Body 2"
            )
        );

        List<NotificationTemplate> emailTemplates =
            templateRepository.findByTenantIdAndType(tenantId1, "EMAIL");
        List<NotificationTemplate> smsTemplates =
            templateRepository.findByTenantIdAndType(tenantId1, "SMS");

        assertThat(emailTemplates).hasSize(2);
        assertThat(emailTemplates)
            .allSatisfy(t ->
                assertThat(t.getType()).isEqualTo("EMAIL")
            );

        assertThat(smsTemplates).hasSize(1);
        assertThat(smsTemplates.get(0).getName()).isEqualTo("SMS 1");
    }

    @Test
    void findByTenantIdAndType_crossTenantIsolation() {
        templateRepository.save(
            createTemplate(
                tenantId1, "Tenant1 Email", "EMAIL",
                "Subject", "Body"
            )
        );
        templateRepository.save(
            createTemplate(
                tenantId2, "Tenant2 Email", "EMAIL",
                "Subject", "Body"
            )
        );

        List<NotificationTemplate> tenant1Emails =
            templateRepository.findByTenantIdAndType(tenantId1, "EMAIL");

        assertThat(tenant1Emails).hasSize(1);
        assertThat(tenant1Emails.get(0).getName())
            .isEqualTo("Tenant1 Email");
    }

    @Test
    void update_modifiesExistingTemplate() {
        NotificationTemplate saved = templateRepository.save(
            createTemplate(
                tenantId1, "Original Name", "EMAIL",
                "Original Subject", "Original Body"
            )
        );

        saved.setName("Updated Name");
        saved.setSubject("Updated Subject");
        saved.setBody("Updated Body");
        saved.setActive(false);
        NotificationTemplate updated = templateRepository.save(saved);

        assertThat(updated.getName()).isEqualTo("Updated Name");
        assertThat(updated.getSubject()).isEqualTo("Updated Subject");
        assertThat(updated.getBody()).isEqualTo("Updated Body");
        assertThat(updated.isActive()).isFalse();
    }

    @Test
    void delete_removesExistingTemplate() {
        NotificationTemplate saved = templateRepository.save(
            createTemplate(
                tenantId1, "To Delete", "EMAIL",
                "Subject", "Body"
            )
        );
        UUID id = saved.getId();

        templateRepository.deleteById(id);
        templateRepository.flush();

        assertThat(templateRepository.findById(id)).isEmpty();
    }

    @Test
    void save_withVariables_persistsJsonb() {
        NotificationTemplate template = createTemplate(
            tenantId1, "With Vars", "EMAIL",
            "Subject {{name}}", "Hello {{name}}, your job {{jobId}}."
        );
        template.setVariables(
            "{\"name\": \"string\", \"jobId\": \"string\"}"
        );

        NotificationTemplate saved = templateRepository.save(template);
        templateRepository.flush();

        NotificationTemplate found =
            templateRepository.findById(saved.getId()).orElseThrow();
        assertThat(found.getVariables()).contains("name");
        assertThat(found.getVariables()).contains("jobId");
    }

    @Test
    void findByTenantId_withNoTemplates_returnsEmptyList() {
        UUID emptyTenantId = TestFixtures.randomTenantId();

        List<NotificationTemplate> templates =
            templateRepository.findByTenantId(emptyTenantId);

        assertThat(templates).isEmpty();
    }

    private NotificationTemplate createTemplate(
        UUID tenantId,
        String name,
        String type,
        String subject,
        String body
    ) {
        NotificationTemplate template = new NotificationTemplate();
        template.setTenantId(tenantId);
        template.setName(name);
        template.setType(type);
        template.setSubject(subject);
        template.setBody(body);
        template.setActive(true);
        return template;
    }
}

package com.cobalt.core.repository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.core.entity.Tenant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@Transactional
class TenantRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private TenantRepository tenantRepository;

    @BeforeEach
    void setUp() {
        tenantRepository.deleteAll();
    }

    @Test
    void save_withValidTenant_persistsAndGeneratesId() {
        Tenant tenant = createTenant("Test HVAC Co", "test-hvac-co");

        Tenant saved = tenantRepository.save(tenant);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getName()).isEqualTo("Test HVAC Co");
        assertThat(saved.getSlug()).isEqualTo("test-hvac-co");
        assertThat(saved.getSubscriptionPlan()).isEqualTo("FREE");
        assertThat(saved.isActive()).isTrue();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
    }

    @Test
    void findById_withExistingTenant_returnsTenant() {
        Tenant saved = tenantRepository.save(
            createTenant("Plumbing Pros", "plumbing-pros")
        );

        Optional<Tenant> found = tenantRepository.findById(saved.getId());

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Plumbing Pros");
        assertThat(found.get().getSlug()).isEqualTo("plumbing-pros");
    }

    @Test
    void findById_withNonExistentId_returnsEmpty() {
        Optional<Tenant> found = tenantRepository.findById(
            UUID.randomUUID()
        );

        assertThat(found).isEmpty();
    }

    @Test
    void findBySlug_withExistingSlug_returnsTenant() {
        tenantRepository.save(
            createTenant("Cool Air Inc", "cool-air-inc")
        );

        Optional<Tenant> found = tenantRepository.findBySlug(
            "cool-air-inc"
        );

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Cool Air Inc");
    }

    @Test
    void findBySlug_withNonExistentSlug_returnsEmpty() {
        Optional<Tenant> found = tenantRepository.findBySlug(
            "nonexistent-slug"
        );

        assertThat(found).isEmpty();
    }

    @Test
    void existsBySlug_withExistingSlug_returnsTrue() {
        tenantRepository.save(
            createTenant("Heating Masters", "heating-masters")
        );

        assertThat(tenantRepository.existsBySlug("heating-masters"))
            .isTrue();
    }

    @Test
    void existsBySlug_withNonExistentSlug_returnsFalse() {
        assertThat(tenantRepository.existsBySlug("no-such-slug"))
            .isFalse();
    }

    @Test
    void save_withDuplicateSlug_throwsDataIntegrityViolation() {
        tenantRepository.save(
            createTenant("First Company", "unique-slug")
        );
        tenantRepository.flush();

        Tenant duplicate = createTenant("Second Company", "unique-slug");

        assertThatThrownBy(() -> {
            tenantRepository.save(duplicate);
            tenantRepository.flush();
        }).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void update_modifiesExistingTenant() {
        Tenant saved = tenantRepository.save(
            createTenant("Old Name", "old-name")
        );

        saved.setName("New Name");
        saved.setSubscriptionPlan("PRO");
        saved.setPhone("555-0100");
        saved.setEmail("contact@newname.com");
        saved.setAddress("123 Main St");
        Tenant updated = tenantRepository.save(saved);

        assertThat(updated.getName()).isEqualTo("New Name");
        assertThat(updated.getSubscriptionPlan()).isEqualTo("PRO");
        assertThat(updated.getPhone()).isEqualTo("555-0100");
        assertThat(updated.getEmail()).isEqualTo("contact@newname.com");
        assertThat(updated.getAddress()).isEqualTo("123 Main St");
    }

    @Test
    void delete_removesExistingTenant() {
        Tenant saved = tenantRepository.save(
            createTenant("To Delete", "to-delete")
        );
        UUID id = saved.getId();

        tenantRepository.deleteById(id);
        tenantRepository.flush();

        assertThat(tenantRepository.findById(id)).isEmpty();
    }

    @Test
    void findAll_returnsAllTenants() {
        tenantRepository.save(createTenant("Tenant A", "tenant-a"));
        tenantRepository.save(createTenant("Tenant B", "tenant-b"));
        tenantRepository.save(createTenant("Tenant C", "tenant-c"));

        assertThat(tenantRepository.findAll()).hasSize(3);
    }

    @Test
    void save_setsCreatedAtAndUpdatedAt() {
        Tenant saved = tenantRepository.save(
            createTenant("Audit Test", "audit-test")
        );

        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
        assertThat(saved.getCreatedAt())
            .isEqualToIgnoringNanos(saved.getUpdatedAt());
    }

    private Tenant createTenant(String name, String slug) {
        Tenant tenant = new Tenant();
        tenant.setName(name);
        tenant.setSlug(slug);
        tenant.setSubscriptionPlan("FREE");
        tenant.setActive(true);
        return tenant;
    }
}

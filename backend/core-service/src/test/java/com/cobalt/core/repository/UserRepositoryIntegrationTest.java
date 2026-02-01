package com.cobalt.core.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.common.test.TestFixtures;
import com.cobalt.core.entity.Tenant;
import com.cobalt.core.entity.User;
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
class UserRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TenantRepository tenantRepository;

    private UUID tenantId1;
    private UUID tenantId2;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        tenantRepository.deleteAll();

        Tenant tenant1 = createTenant("Tenant One", "tenant-one");
        tenant1 = tenantRepository.save(tenant1);
        tenantId1 = tenant1.getId();

        Tenant tenant2 = createTenant("Tenant Two", "tenant-two");
        tenant2 = tenantRepository.save(tenant2);
        tenantId2 = tenant2.getId();
    }

    @Test
    void save_withValidUser_persistsAndGeneratesId() {
        User user = createUser(
            tenantId1, "john@test.com", "John", "Doe", "ADMIN"
        );

        User saved = userRepository.save(user);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getTenantId()).isEqualTo(tenantId1);
        assertThat(saved.getEmail()).isEqualTo("john@test.com");
        assertThat(saved.getFirstName()).isEqualTo("John");
        assertThat(saved.getLastName()).isEqualTo("Doe");
        assertThat(saved.getRole()).isEqualTo("ADMIN");
        assertThat(saved.isActive()).isTrue();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
    }

    @Test
    void findByEmail_withExistingEmail_returnsUser() {
        userRepository.save(
            createUser(
                tenantId1, "jane@test.com", "Jane", "Smith", "MANAGER"
            )
        );

        Optional<User> found = userRepository.findByEmail(
            "jane@test.com"
        );

        assertThat(found).isPresent();
        assertThat(found.get().getFirstName()).isEqualTo("Jane");
        assertThat(found.get().getLastName()).isEqualTo("Smith");
    }

    @Test
    void findByEmail_withNonExistentEmail_returnsEmpty() {
        Optional<User> found = userRepository.findByEmail(
            "nobody@test.com"
        );

        assertThat(found).isEmpty();
    }

    @Test
    void findByTenantIdAndEmail_returnsTenantScopedUser() {
        userRepository.save(
            createUser(
                tenantId1, "user@test.com", "User", "One", "TECHNICIAN"
            )
        );

        Optional<User> found = userRepository.findByTenantIdAndEmail(
            tenantId1, "user@test.com"
        );

        assertThat(found).isPresent();
        assertThat(found.get().getTenantId()).isEqualTo(tenantId1);
    }

    @Test
    void findByTenantIdAndEmail_withWrongTenant_returnsEmpty() {
        userRepository.save(
            createUser(
                tenantId1, "user@test.com", "User", "One", "TECHNICIAN"
            )
        );

        Optional<User> found = userRepository.findByTenantIdAndEmail(
            tenantId2, "user@test.com"
        );

        assertThat(found).isEmpty();
    }

    @Test
    void existsByTenantIdAndEmail_withExistingUser_returnsTrue() {
        userRepository.save(
            createUser(
                tenantId1, "exists@test.com", "Test", "User", "ADMIN"
            )
        );

        assertThat(
            userRepository.existsByTenantIdAndEmail(
                tenantId1, "exists@test.com"
            )
        ).isTrue();
    }

    @Test
    void existsByTenantIdAndEmail_withWrongTenant_returnsFalse() {
        userRepository.save(
            createUser(
                tenantId1, "exists@test.com", "Test", "User", "ADMIN"
            )
        );

        assertThat(
            userRepository.existsByTenantIdAndEmail(
                tenantId2, "exists@test.com"
            )
        ).isFalse();
    }

    @Test
    void findByTenantId_returnsOnlyUsersForTenant() {
        userRepository.save(
            createUser(tenantId1, "a@t1.com", "A", "One", "ADMIN")
        );
        userRepository.save(
            createUser(tenantId1, "b@t1.com", "B", "One", "MANAGER")
        );
        userRepository.save(
            createUser(
                tenantId2, "c@t2.com", "C", "Two", "TECHNICIAN"
            )
        );

        List<User> tenant1Users = userRepository.findByTenantId(
            tenantId1
        );
        List<User> tenant2Users = userRepository.findByTenantId(
            tenantId2
        );

        assertThat(tenant1Users).hasSize(2);
        assertThat(tenant1Users)
            .allSatisfy(u ->
                assertThat(u.getTenantId()).isEqualTo(tenantId1)
            );

        assertThat(tenant2Users).hasSize(1);
        assertThat(tenant2Users.get(0).getEmail()).isEqualTo("c@t2.com");
    }

    @Test
    void findByTenantId_withNoUsers_returnsEmptyList() {
        UUID emptyTenantId = TestFixtures.randomTenantId();

        List<User> users = userRepository.findByTenantId(emptyTenantId);

        assertThat(users).isEmpty();
    }

    @Test
    void tenantIsolation_usersFromDifferentTenants_doNotLeak() {
        userRepository.save(
            createUser(
                tenantId1, "secret@t1.com", "Secret", "Data", "ADMIN"
            )
        );
        userRepository.save(
            createUser(
                tenantId2, "other@t2.com", "Other", "Data", "ADMIN"
            )
        );

        List<User> tenant1Users = userRepository.findByTenantId(
            tenantId1
        );
        List<User> tenant2Users = userRepository.findByTenantId(
            tenantId2
        );

        assertThat(tenant1Users).hasSize(1);
        assertThat(tenant1Users.get(0).getEmail())
            .isEqualTo("secret@t1.com");

        assertThat(tenant2Users).hasSize(1);
        assertThat(tenant2Users.get(0).getEmail())
            .isEqualTo("other@t2.com");

        // Verify no cross-tenant access
        assertThat(tenant1Users)
            .noneMatch(u -> u.getEmail().equals("other@t2.com"));
        assertThat(tenant2Users)
            .noneMatch(u -> u.getEmail().equals("secret@t1.com"));
    }

    @Test
    void update_modifiesExistingUser() {
        User saved = userRepository.save(
            createUser(
                tenantId1, "update@test.com", "Before", "Update",
                "TECHNICIAN"
            )
        );

        saved.setFirstName("After");
        saved.setRole("MANAGER");
        saved.setPhone("555-0199");
        User updated = userRepository.save(saved);

        assertThat(updated.getFirstName()).isEqualTo("After");
        assertThat(updated.getRole()).isEqualTo("MANAGER");
        assertThat(updated.getPhone()).isEqualTo("555-0199");
    }

    @Test
    void delete_removesExistingUser() {
        User saved = userRepository.save(
            createUser(
                tenantId1, "delete@test.com", "To", "Delete", "ADMIN"
            )
        );
        UUID id = saved.getId();

        userRepository.deleteById(id);
        userRepository.flush();

        assertThat(userRepository.findById(id)).isEmpty();
    }

    private User createUser(
        UUID tenantId,
        String email,
        String firstName,
        String lastName,
        String role
    ) {
        User user = new User();
        user.setTenantId(tenantId);
        user.setEmail(email);
        user.setPasswordHash("$2a$10$hashed_password_placeholder");
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setRole(role);
        user.setActive(true);
        return user;
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

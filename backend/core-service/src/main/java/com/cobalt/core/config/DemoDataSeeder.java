package com.cobalt.core.config;

import com.cobalt.core.entity.Tenant;
import com.cobalt.core.entity.User;
import com.cobalt.core.repository.TenantRepository;
import com.cobalt.core.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Profile("dev")
public class DemoDataSeeder implements ApplicationRunner {

    private static final Logger LOG =
        LoggerFactory.getLogger(DemoDataSeeder.class);

    private static final String DEMO_SLUG = "demo";
    private static final String DEFAULT_PASSWORD = "password123";

    private final TenantRepository tenantRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DemoDataSeeder(
        TenantRepository tenantRepository,
        UserRepository userRepository,
        PasswordEncoder passwordEncoder
    ) {
        this.tenantRepository = tenantRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (tenantRepository.existsBySlug(DEMO_SLUG)) {
            LOG.info("Demo tenant already exists, skipping seed");
            return;
        }

        LOG.info("Creating demo tenant and users...");

        Tenant tenant = new Tenant();
        tenant.setName("Demo Company");
        tenant.setSlug(DEMO_SLUG);
        tenant.setSubscriptionPlan("FREE");
        tenant.setActive(true);
        tenant = tenantRepository.save(tenant);

        String encoded = passwordEncoder.encode(DEFAULT_PASSWORD);

        createUser(
            tenant, "admin@demo.com", encoded,
            "Admin", "User", "ADMIN"
        );
        createUser(
            tenant, "manager@demo.com", encoded,
            "Manager", "User", "MANAGER"
        );
        createUser(
            tenant, "tech@demo.com", encoded,
            "Tech", "User", "TECHNICIAN"
        );

        LOG.info("Demo data seeding complete");
    }

    private void createUser(
        Tenant tenant,
        String email,
        String passwordHash,
        String firstName,
        String lastName,
        String role
    ) {
        User user = new User();
        user.setTenantId(tenant.getId());
        user.setEmail(email);
        user.setPasswordHash(passwordHash);
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setRole(role);
        user.setActive(true);
        userRepository.save(user);
    }
}

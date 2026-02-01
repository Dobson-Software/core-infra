package com.cobalt.common.test;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;

public abstract class AbstractIntegrationTest {

    protected static final PostgreSQLContainer<?> POSTGRES;

    static {
        POSTGRES = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("cobalt_test")
            .withUsername("cobalt_test")
            .withPassword("cobalt_test");
        POSTGRES.start();
    }

    @DynamicPropertySource
    static void configureDataSource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add(
            "spring.datasource.username", POSTGRES::getUsername
        );
        registry.add(
            "spring.datasource.password", POSTGRES::getPassword
        );
    }
}

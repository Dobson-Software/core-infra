package com.cobalt.core;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@Testcontainers
class CoreServiceApplicationTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES =
        new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("cobalt_test")
            .withUsername("cobalt_test")
            .withPassword("cobalt_test");

    @DynamicPropertySource
    static void configureDataSource(
        DynamicPropertyRegistry registry
    ) {
        registry.add(
            "spring.datasource.url", POSTGRES::getJdbcUrl
        );
        registry.add(
            "spring.datasource.username", POSTGRES::getUsername
        );
        registry.add(
            "spring.datasource.password", POSTGRES::getPassword
        );
    }

    @Test
    void contextLoads() {
        // Verifies Spring context starts successfully
    }
}

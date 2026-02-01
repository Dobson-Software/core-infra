plugins {
    id("java-library")
    id("java-test-fixtures")
    id("org.springframework.boot")
    id("io.spring.dependency-management")
}

tasks.bootJar {
    enabled = false
}

tasks.jar {
    enabled = true
}

dependencies {
    // Spring Boot
    api("org.springframework.boot:spring-boot-starter-web")
    api("org.springframework.boot:spring-boot-starter-data-jpa")
    api("org.springframework.boot:spring-boot-starter-validation")
    api("org.springframework.boot:spring-boot-starter-security")
    api("org.springframework.boot:spring-boot-starter-actuator")
    api("org.springframework.boot:spring-boot-starter-cache")
    api("com.github.ben-manes.caffeine:caffeine")

    // JWT
    api("io.jsonwebtoken:jjwt-api:0.13.0")
    api("io.jsonwebtoken:jjwt-impl:0.13.0")
    api("io.jsonwebtoken:jjwt-jackson:0.13.0")

    // MapStruct
    api("org.mapstruct:mapstruct:1.6.3")
    annotationProcessor("org.mapstruct:mapstruct-processor:1.6.3")

    // Lombok
    compileOnly("org.projectlombok:lombok:1.18.42")
    annotationProcessor("org.projectlombok:lombok:1.18.42")
    annotationProcessor("org.projectlombok:lombok-mapstruct-binding:0.2.0")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")

    // Test Fixtures
    testFixturesImplementation("org.springframework.boot:spring-boot-starter-test")
    testFixturesImplementation("org.springframework:spring-test")
    testFixturesImplementation("org.testcontainers:testcontainers:1.21.4")
    testFixturesImplementation("org.testcontainers:junit-jupiter:1.21.4")
    testFixturesImplementation("org.testcontainers:postgresql:1.21.4")
}

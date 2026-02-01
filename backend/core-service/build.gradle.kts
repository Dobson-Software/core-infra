plugins {
    id("org.springframework.boot")
    id("io.spring.dependency-management")
}

dependencies {
    implementation(project(":platform-common"))
    testImplementation(testFixtures(project(":platform-common")))

    // Spring Boot
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-data-redis")
    implementation("org.springframework.boot:spring-boot-starter-websocket")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    // Database
    runtimeOnly("org.postgresql:postgresql")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")

    // MapStruct
    implementation("org.mapstruct:mapstruct:1.6.3")
    annotationProcessor("org.mapstruct:mapstruct-processor:1.6.3")

    // Lombok
    compileOnly("org.projectlombok:lombok:1.18.42")
    annotationProcessor("org.projectlombok:lombok:1.18.42")
    annotationProcessor("org.projectlombok:lombok-mapstruct-binding:0.2.0")

    // Stripe
    implementation("com.stripe:stripe-java:24.15.0")

    // Twilio
    implementation("com.twilio.sdk:twilio:10.1.0")

    // PDF generation
    implementation("com.openhtmltopdf:openhtmltopdf-pdfbox:1.0.10")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.testcontainers:testcontainers:1.21.4")
    testImplementation("org.testcontainers:junit-jupiter:1.21.4")
    testImplementation("org.testcontainers:postgresql:1.21.4")
    testImplementation("com.icegreen:greenmail-junit5:2.1.8")
    testImplementation("com.github.tomakehurst:wiremock-jre8-standalone:3.0.1")
}

tasks.bootJar {
    archiveFileName.set("core-service.jar")
}

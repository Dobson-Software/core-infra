plugins {
    java
    id("org.springframework.boot") version "3.5.10" apply false
    id("io.spring.dependency-management") version "1.1.7" apply false
    checkstyle
    jacoco
    id("org.owasp.dependencycheck") version "12.2.0"
}

val javaVersion = JavaVersion.toVersion(21)
val checkstyleVersion = "10.12.5"
val jacocoVersion = "0.8.11"
val mapstructVersion = "1.5.5.Final"
val lombokVersion = "1.18.42"
val lombokMapstructBindingVersion = "0.2.0"

allprojects {
    group = "com.cobalt"
    version = "0.0.1-SNAPSHOT"

    repositories {
        mavenCentral()
    }
}

subprojects {
    apply(plugin = "java")
    apply(plugin = "checkstyle")
    apply(plugin = "jacoco")

    java {
        sourceCompatibility = javaVersion
        targetCompatibility = javaVersion
    }

    checkstyle {
        toolVersion = checkstyleVersion
        configFile = rootProject.file("config/checkstyle/checkstyle.xml")
        isIgnoreFailures = false
        maxWarnings = 0
    }

    jacoco {
        toolVersion = jacocoVersion
    }

    tasks.withType<JavaCompile> {
        options.encoding = "UTF-8"
        options.compilerArgs.addAll(listOf("-parameters"))
    }

    tasks.withType<org.springframework.boot.gradle.tasks.bundling.BootJar> {
        archiveFileName.set("${project.name}.jar")
    }

    tasks.withType<Test> {
        useJUnitPlatform()
        jvmArgs("-XX:+EnableDynamicAgentLoading")
    }

    tasks.jacocoTestReport {
        dependsOn(tasks.test)
        reports {
            xml.required.set(true)
            html.required.set(true)
        }
    }

    tasks.jacocoTestCoverageVerification {
        violationRules {
            rule {
                limit {
                    minimum = "0.80".toBigDecimal()
                }
                excludes = listOf(
                    "com.cobalt.*.entity.*",
                    "com.cobalt.*.dto.*",
                    "com.cobalt.*.config.*",
                    "com.cobalt.*.*Application",
                    "com.cobalt.common.security.UserPrincipal",
                    "com.cobalt.common.security.TenantContext",
                    "com.cobalt.common.security.Role"
                )
            }
            rule {
                element = "CLASS"
                includes = listOf("com.cobalt.*.service.*")
                limit {
                    minimum = "0.95".toBigDecimal()
                }
            }
        }
    }

    tasks.check {
        dependsOn(tasks.jacocoTestCoverageVerification)
    }

    // NO-MOCK policy enforcement
    tasks.register("checkNoMocks") {
        group = "verification"
        description = "Ensures no mocking frameworks are used in test code"

        doLast {
            val forbiddenPatterns = listOf(
                "import org.mockito",
                "import static org.mockito",
                "@Mock",
                "@MockBean",
                "@SpyBean",
                "Mockito.mock(",
                "Mockito.when(",
                "Mockito.verify(",
                "mock(",
                "when(",
                "import io.mockk",
                "@MockK",
                "mockk(",
                "every {",
                "coEvery {"
            )

            val testDirs = listOf(
                file("src/test/java"),
                file("src/integrationTest/java")
            )

            var violations = 0
            testDirs.filter { it.exists() }.forEach { dir ->
                dir.walkTopDown()
                    .filter { it.extension == "java" || it.extension == "kt" }
                    .forEach { file ->
                        val lines = file.readLines()
                        lines.forEachIndexed { index, line ->
                            forbiddenPatterns.forEach { pattern ->
                                if (line.contains(pattern)) {
                                    logger.error("MOCK VIOLATION: ${file.relativeTo(projectDir)}:${index + 1} — $pattern")
                                    violations++
                                }
                            }
                        }
                    }
            }

            if (violations > 0) {
                throw GradleException("Found $violations mock violation(s). Use TestContainers, GreenMail, or WireMock instead.")
            }

            logger.lifecycle("NO-MOCK check passed — no mock violations found.")
        }
    }

    tasks.check {
        dependsOn("checkNoMocks")
    }

    // Integration test source set
    sourceSets {
        create("integrationTest") {
            java.srcDir("src/integrationTest/java")
            resources.srcDir("src/integrationTest/resources")
            compileClasspath += sourceSets["main"].output + sourceSets["test"].output
            runtimeClasspath += sourceSets["main"].output + sourceSets["test"].output
        }
    }

    configurations["integrationTestImplementation"].extendsFrom(configurations["testImplementation"])
    configurations["integrationTestRuntimeOnly"].extendsFrom(configurations["testRuntimeOnly"])

    tasks.register<Test>("integrationTest") {
        group = "verification"
        description = "Runs integration tests"
        testClassesDirs = sourceSets["integrationTest"].output.classesDirs
        classpath = sourceSets["integrationTest"].runtimeClasspath
        shouldRunAfter(tasks.test)
    }
}

// OWASP Dependency-Check configuration
// Run separately: ./gradlew dependencyCheckAggregate
// NOT wired to `check` task to avoid slowing local builds
dependencyCheck {
    failBuildOnCVSS = 7.0f
    suppressionFile = "config/owasp-suppressions.xml"
    analyzers.apply {
        assemblyEnabled = false
        nuspecEnabled = false
        nugetconfEnabled = false
        nodeEnabled = false
        nodeAuditEnabled = false
    }
}

// Frontend build tasks (delegated to pnpm/turbo)
tasks.register<Exec>("frontendInstall") {
    group = "frontend"
    description = "Install frontend dependencies"
    workingDir = file("../frontend")
    commandLine("pnpm", "install", "--frozen-lockfile")
}

tasks.register<Exec>("frontendUnitTest") {
    group = "frontend"
    description = "Run frontend unit tests"
    workingDir = file("../frontend")
    commandLine("pnpm", "test:run")
    dependsOn("frontendInstall")
}

tasks.register<Exec>("frontendE2ETest") {
    group = "frontend"
    description = "Run frontend E2E tests"
    workingDir = file("../frontend")
    commandLine("pnpm", "test:e2e")
    dependsOn("frontendInstall")
}

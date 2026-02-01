package com.cobalt.violations.repository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cobalt.common.test.AbstractIntegrationTest;
import com.cobalt.violations.entity.DobViolation;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
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
class DobViolationRepositoryIntegrationTest
        extends AbstractIntegrationTest {

    @Autowired
    private DobViolationRepository violationRepository;

    @BeforeEach
    void setUp() {
        violationRepository.deleteAll();
    }

    @Test
    void save_withValidViolation_persistsAndGeneratesId() {
        DobViolation violation = createViolation(
            "V-001", "MANHATTAN", "1234567"
        );

        DobViolation saved = violationRepository.save(violation);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getIsnDobBisViol()).isEqualTo("V-001");
        assertThat(saved.getBoro()).isEqualTo("MANHATTAN");
        assertThat(saved.getBin()).isEqualTo("1234567");
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
        assertThat(saved.getSyncedAt()).isNotNull();
    }

    @Test
    void save_withAllFields_persistsCorrectly() {
        DobViolation violation = createViolation(
            "V-FULL", "BROOKLYN", "7654321"
        );
        violation.setBlock("01234");
        violation.setLot("0056");
        violation.setIssueDate(LocalDate.of(2024, 6, 15));
        violation.setViolationTypeCode("VT01");
        violation.setViolationNumber("VN-2024-001");
        violation.setHouseNumber("123");
        violation.setStreet("Broadway");
        violation.setDispositionDate(LocalDate.of(2024, 9, 1));
        violation.setDispositionComments("Resolved");
        violation.setDeviceNumber("DEV-001");
        violation.setDescription("Boiler inspection failure");
        violation.setEcbNumber("ECB-001");
        violation.setNumber("NUM-001");
        violation.setViolationCategory("BOILER");
        violation.setViolationType("PLUMBING");
        violation.setRawData("{\"original\": \"data\"}");

        DobViolation saved = violationRepository.save(violation);
        violationRepository.flush();

        DobViolation found =
            violationRepository.findById(saved.getId()).orElseThrow();
        assertThat(found.getBlock()).isEqualTo("01234");
        assertThat(found.getLot()).isEqualTo("0056");
        assertThat(found.getIssueDate())
            .isEqualTo(LocalDate.of(2024, 6, 15));
        assertThat(found.getViolationTypeCode()).isEqualTo("VT01");
        assertThat(found.getStreet()).isEqualTo("Broadway");
        assertThat(found.getDispositionDate())
            .isEqualTo(LocalDate.of(2024, 9, 1));
        assertThat(found.getDispositionComments()).isEqualTo("Resolved");
        assertThat(found.getDescription())
            .isEqualTo("Boiler inspection failure");
        assertThat(found.getViolationType()).isEqualTo("PLUMBING");
        assertThat(found.getRawData()).contains("original");
    }

    @Test
    void findById_withNonExistentId_returnsEmpty() {
        Optional<DobViolation> found =
            violationRepository.findById(UUID.randomUUID());

        assertThat(found).isEmpty();
    }

    @Test
    void findByBin_returnsMatchingViolations() {
        violationRepository.save(
            createViolation("V-BIN-1", "MANHATTAN", "9999999")
        );
        violationRepository.save(
            createViolation("V-BIN-2", "MANHATTAN", "9999999")
        );
        violationRepository.save(
            createViolation("V-BIN-3", "BROOKLYN", "8888888")
        );

        List<DobViolation> violations =
            violationRepository.findByBin("9999999");

        assertThat(violations).hasSize(2);
        assertThat(violations)
            .allSatisfy(v ->
                assertThat(v.getBin()).isEqualTo("9999999")
            );
    }

    @Test
    void findByBoro_returnsMatchingViolations() {
        violationRepository.save(
            createViolation("V-B-1", "MANHATTAN", "1111111")
        );
        violationRepository.save(
            createViolation("V-B-2", "MANHATTAN", "2222222")
        );
        violationRepository.save(
            createViolation("V-B-3", "BROOKLYN", "3333333")
        );

        List<DobViolation> manhattan =
            violationRepository.findByBoro("MANHATTAN");

        assertThat(manhattan).hasSize(2);
        assertThat(manhattan)
            .allSatisfy(v ->
                assertThat(v.getBoro()).isEqualTo("MANHATTAN")
            );
    }

    @Test
    void findByIsnDobBisViol_returnsMatchingViolation() {
        violationRepository.save(
            createViolation("V-FIND-1", "MANHATTAN", "1234567")
        );

        Optional<DobViolation> found =
            violationRepository.findByIsnDobBisViol("V-FIND-1");

        assertThat(found).isPresent();
        assertThat(found.get().getBoro()).isEqualTo("MANHATTAN");
    }

    @Test
    void findByIsnDobBisViol_withNonExistent_returnsEmpty() {
        Optional<DobViolation> found =
            violationRepository.findByIsnDobBisViol("NONEXISTENT");

        assertThat(found).isEmpty();
    }

    @Test
    void upsert_insertNewViolation_thenUpdateExisting() {
        DobViolation violation = createViolation(
            "V-UPSERT", "MANHATTAN", "1234567"
        );
        violation.setDescription("Original description");
        DobViolation saved = violationRepository.save(violation);
        violationRepository.flush();

        UUID originalId = saved.getId();

        saved.setDescription("Updated description");
        saved.setDispositionDate(LocalDate.of(2024, 12, 1));
        saved.setDispositionComments("Violation resolved");
        DobViolation updated = violationRepository.save(saved);
        violationRepository.flush();

        assertThat(updated.getId()).isEqualTo(originalId);
        assertThat(updated.getDescription())
            .isEqualTo("Updated description");
        assertThat(updated.getDispositionComments())
            .isEqualTo("Violation resolved");
    }

    @Test
    void uniqueConstraint_sameIsn_throwsException() {
        violationRepository.save(
            createViolation("V-DUP", "MANHATTAN", "1234567")
        );
        violationRepository.flush();

        DobViolation duplicate = createViolation(
            "V-DUP", "BROOKLYN", "7654321"
        );

        assertThatThrownBy(() -> {
            violationRepository.save(duplicate);
            violationRepository.flush();
        }).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void delete_removesExistingViolation() {
        DobViolation saved = violationRepository.save(
            createViolation("V-DEL", "MANHATTAN", "1234567")
        );
        UUID id = saved.getId();

        violationRepository.deleteById(id);
        violationRepository.flush();

        assertThat(violationRepository.findById(id)).isEmpty();
    }

    @Test
    void save_setsTimestampsAutomatically() {
        DobViolation violation = createViolation(
            "V-TS", "QUEENS", "4444444"
        );

        DobViolation saved = violationRepository.save(violation);

        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
        assertThat(saved.getSyncedAt()).isNotNull();
    }

    private DobViolation createViolation(
        String isnDobBisViol,
        String boro,
        String bin
    ) {
        DobViolation violation = new DobViolation();
        violation.setIsnDobBisViol(isnDobBisViol);
        violation.setBoro(boro);
        violation.setBin(bin);
        violation.setSyncedAt(LocalDateTime.now());
        return violation;
    }
}

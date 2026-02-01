package com.cobalt.violations.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "dob_violations", schema = "violations",
    uniqueConstraints = @UniqueConstraint(columnNames = {"isn_dob_bis_viol"}))
@Getter
@Setter
@NoArgsConstructor
public class DobViolation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "isn_dob_bis_viol", length = 100)
    private String isnDobBisViol;

    @Column(length = 50)
    private String boro;

    @Column(length = 20)
    private String bin;

    @Column(length = 20)
    private String block;

    @Column(length = 20)
    private String lot;

    @Column(name = "issue_date")
    private LocalDate issueDate;

    @Column(name = "violation_type_code", length = 20)
    private String violationTypeCode;

    @Column(name = "violation_number", length = 50)
    private String violationNumber;

    @Column(name = "house_number", length = 50)
    private String houseNumber;

    @Column(length = 255)
    private String street;

    @Column(name = "disposition_date")
    private LocalDate dispositionDate;

    @Column(name = "disposition_comments", columnDefinition = "TEXT")
    private String dispositionComments;

    @Column(name = "device_number", length = 50)
    private String deviceNumber;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "ecb_number", length = 50)
    private String ecbNumber;

    @Column(length = 50)
    private String number;

    @Column(name = "violation_category", length = 100)
    private String violationCategory;

    @Column(name = "violation_type", length = 100)
    private String violationType;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "raw_data", columnDefinition = "jsonb")
    private String rawData;

    @Column(name = "synced_at", nullable = false)
    private LocalDateTime syncedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
        if (syncedAt == null) {
            syncedAt = now;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

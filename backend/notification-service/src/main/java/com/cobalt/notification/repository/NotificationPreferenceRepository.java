package com.cobalt.notification.repository;

import com.cobalt.notification.entity.NotificationPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationPreferenceRepository
        extends JpaRepository<NotificationPreference, UUID> {

    List<NotificationPreference> findByTenantIdAndUserId(
            UUID tenantId, UUID userId);
}

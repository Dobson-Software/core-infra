package com.cobalt.notification.repository;

import com.cobalt.notification.entity.NotificationTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationTemplateRepository
        extends JpaRepository<NotificationTemplate, UUID> {

    List<NotificationTemplate> findByTenantId(UUID tenantId);

    List<NotificationTemplate> findByTenantIdAndType(
            UUID tenantId, String type);
}

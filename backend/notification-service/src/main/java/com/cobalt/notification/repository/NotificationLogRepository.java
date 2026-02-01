package com.cobalt.notification.repository;

import com.cobalt.notification.entity.NotificationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationLogRepository
        extends JpaRepository<NotificationLog, UUID> {

    List<NotificationLog> findByTenantId(UUID tenantId);
}

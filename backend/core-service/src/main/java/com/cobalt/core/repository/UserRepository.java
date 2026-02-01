package com.cobalt.core.repository;

import com.cobalt.core.entity.User;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);

    Optional<User> findByTenantIdAndEmail(
        UUID tenantId, String email
    );

    boolean existsByTenantIdAndEmail(UUID tenantId, String email);

    List<User> findByTenantId(UUID tenantId);
}

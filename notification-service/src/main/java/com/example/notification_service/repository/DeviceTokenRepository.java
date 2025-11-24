package com.example.notification_service.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.notification_service.entity.DeviceToken;
import com.google.common.base.Optional;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    Optional<DeviceToken> findByUserId(String userId);
}

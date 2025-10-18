package com.example.notification_service.dto;

/**
 * DeviceRegistrationRequest
 */
public record DeviceRegistrationRequest(
  Long userId,
  String fcmToken
) {
}

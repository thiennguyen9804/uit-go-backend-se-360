package com.example.notification_service.dto;

/**
 * DeviceRegistrationRequest
 */
public record DeviceRegistrationRequest(
  String userId,
  String fcmToken
) {
}

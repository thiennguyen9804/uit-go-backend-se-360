package com.example.notification_service.service;

import org.springframework.stereotype.Service;

import com.example.notification_service.entity.DeviceToken;
import com.example.notification_service.repository.DeviceTokenRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class NotificationService {
  private final DeviceTokenRepository deviceTokenRepository;

  public void saveToken(String userId, String fcmToken) {
    // DeviceToken deviceToken = DeviceToken.builder()
    //     .userId(userId)
    //     .fcmToken(fcmToken)
    //     .build();
    DeviceToken deviceToken = new DeviceToken();
    deviceToken.setUserId(userId);
    deviceToken.setFcmToken(fcmToken);
    deviceTokenRepository.save(deviceToken);
  }


}

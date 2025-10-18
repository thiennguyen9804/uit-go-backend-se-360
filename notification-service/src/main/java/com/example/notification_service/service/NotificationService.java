package com.example.notification_service.service;

import org.springframework.stereotype.Service;

import com.example.notification_service.entity.DeviceToken;
import com.example.notification_service.repository.DeviceTokenRepository;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class NotificationService {
  private final DeviceTokenRepository deviceTokenRepository;

  public void saveToken(String userId, String fcmToken) {
    DeviceToken deviceToken = DeviceToken.builder()
        .userId(userId)
        .fcmToken(fcmToken)
        .build();

    deviceTokenRepository.save(deviceToken);
  }


}

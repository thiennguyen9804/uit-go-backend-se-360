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

  private String getToken(String userId) {
    return deviceTokenRepository.findById(userId)
        .map(DeviceToken::getFcmToken)
        .orElse(null);
  }

  public void sendNotification(String userId, String title, String body) {
    String fcmToken = getToken(userId);
    if (fcmToken == null) {
      System.err.println("No FCM token for user: " + userId);
      return;
    }

    Message message = Message.builder()
        .setToken(fcmToken)
        .setNotification(
            Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build())
        .build();

    try {
      String response = FirebaseMessaging.getInstance().send(message);
      System.out.println("Successfully sent message: " + response);
    } catch (Exception e) {
      System.err.println("Failed to send notification: " + e.getMessage());
      if (e.getMessage().contains("NotRegistered")) {
        deviceTokenRepository.deleteById(userId);
      }
    }
  }
}

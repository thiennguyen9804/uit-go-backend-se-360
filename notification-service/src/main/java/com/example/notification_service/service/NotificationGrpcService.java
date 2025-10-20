package com.example.notification_service.service;

import org.springframework.grpc.server.service.GrpcService;

import com.example.notification_service.entity.DeviceToken;
import com.example.notification_service.repository.DeviceTokenRepository;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

import io.grpc.stub.StreamObserver;
import lombok.RequiredArgsConstructor;

@GrpcService
@RequiredArgsConstructor
public class NotificationGrpcService extends NotificationServiceGrpc.NotificationServiceImplBase {
  private final DeviceTokenRepository deviceTokenRepository;

  @Override
  public void sendNotification(SendNotificationRequest request,
      StreamObserver<SendNotificationResponse> responseObserver) {
    Long driverId = request.getDriverId();
    String fcmToken = deviceTokenRepository.findById(driverId)
        .map(DeviceToken::getFcmToken)
        .orElse(null);
    if (fcmToken == null) {
      responseObserver.onNext(SendNotificationResponse.newBuilder()
          .setSuccess(false)
          .setMessage("No FCM token for driver: " + driverId)
          .build());
      responseObserver.onCompleted();
      return;
    }
    Notification notification = Notification.builder()
        .setTitle(request.getTitle())
        .setBody(request.getBody())
        .build();
    Message message = Message.builder()
        .setToken(fcmToken)
        .setNotification(notification)
        .putData("driverId", driverId.toString())
        .build();
    try {
      String response = FirebaseMessaging.getInstance().send(message);
      responseObserver.onNext(SendNotificationResponse.newBuilder()
          .setSuccess(true)
          .setMessage("Successfully sent notification: " + response)
          .build());
    } catch (Exception e) {
      responseObserver.onNext(SendNotificationResponse.newBuilder()
          .setSuccess(false)
          .setMessage("Failed to send notification: " + e.getMessage())
          .build());
      if (e.getMessage().contains("NotRegistered")) {
        deviceTokenRepository.deleteById(driverId);
      }
    }
    responseObserver.onCompleted();
  }
}

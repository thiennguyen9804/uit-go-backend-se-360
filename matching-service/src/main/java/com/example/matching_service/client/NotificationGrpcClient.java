package com.example.matching_service.client;

import org.springframework.stereotype.Component;

import com.example.notification_service.proto.NotificationServiceGrpc;
import com.example.notification_service.proto.SendNotificationRequest;
import com.example.notification_service.proto.SendNotificationResponse;

import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;

@Component
public class NotificationGrpcClient {
  private final NotificationServiceGrpc.NotificationServiceBlockingStub blockingStub;

  public NotificationGrpcClient() {
    ManagedChannel channel = ManagedChannelBuilder.forAddress("notification-service", 28084)
        .usePlaintext()
        .build();
    this.blockingStub = NotificationServiceGrpc.newBlockingStub(channel);
  }

  public boolean sendNotification(String driverId, String title, String body) {
    SendNotificationRequest request = SendNotificationRequest.newBuilder()
        .setDriverId(driverId)
        .setTitle(title)
        .setBody(body)
        .build();

    SendNotificationResponse response = blockingStub.sendNotification(request);
    if (!response.getSuccess()) {
      System.err.println("Failed to send notification: " + response.getMessage());
    }
    return response.getSuccess();
  }
}

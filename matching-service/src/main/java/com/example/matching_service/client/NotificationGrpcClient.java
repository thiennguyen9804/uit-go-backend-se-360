package com.example.matching_service.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.example.notification_service.proto.NotificationServiceGrpc;
import com.example.notification_service.proto.SendNotificationRequest;
import com.example.notification_service.proto.SendNotificationResponse;

import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.StatusRuntimeException;

@Component
public class NotificationGrpcClient {
  private final NotificationServiceGrpc.NotificationServiceBlockingStub blockingStub;
  private final Logger logger = LoggerFactory.getLogger(NotificationGrpcClient.class);

  public NotificationGrpcClient() {
    ManagedChannel channel = ManagedChannelBuilder
        .forAddress("notification-service", 28084)
        .usePlaintext()
        .build();
    if (channel.isShutdown() || channel.isTerminated()) {
      logger.error("gRPC channel is not active");
      throw new IllegalStateException("gRPC channel is not active");
    }
    this.blockingStub = NotificationServiceGrpc.newBlockingStub(channel);
  }

  public boolean sendNotification(Long driverId, String title, String body) {
    SendNotificationRequest request = SendNotificationRequest.newBuilder()
        .setDriverId(driverId)
        .setTitle(title)
        .setBody(body)
        .build();

    SendNotificationResponse response = SendNotificationResponse.newBuilder()
        .setSuccess(false)
        .setMessage("Failed to send notification due to gRPC error")
        .build();
    try {
      response = blockingStub.sendNotification(request);
    } catch (StatusRuntimeException e) {
      logger.error("GRPC Status Code: " + e.getStatus().getCode().toString());
      e.printStackTrace();
    }

    if (!response.getSuccess()) {
      System.err.println("Failed to send notification: " + response.getMessage());
    }
    return response.getSuccess();
  }
}

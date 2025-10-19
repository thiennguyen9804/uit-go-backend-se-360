package com.example.matching_service.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import com.example.matching_service.client.NotificationGrpcClient;
import com.example.trip_service.dto.TripEvent;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
class MatchingService {
  private static final Logger logger = LoggerFactory.getLogger(MatchingService.class);
  private final NotificationGrpcClient notificationClient;

  @KafkaListener(topics = "trip-events")
  public void listen(TripEvent tripEvent) {
    logger.info("MatchingService received trip events");
    Long driverId = 1L;
    boolean success = notificationClient.sendNotification(
        driverId,
        "New Trip Assignment",
        "You have been assigned a new trip: " + tripEvent.getTripId()
    );

    if (success) {
      logger.info("Successfully sent notification to driverId: {}", driverId);
    } else {
      logger.error("Failed to send notification to driverId: {}", driverId);
    }
  }

}

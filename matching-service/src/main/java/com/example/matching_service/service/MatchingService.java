package com.example.matching_service.service;

import java.util.List;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.geo.Circle;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.data.redis.connection.RedisGeoCommands.GeoLocation;
import org.springframework.data.redis.core.GeoOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.example.matching_service.client.NotificationGrpcClient;
import com.example.matching_service.dto.TripLocationData;
import com.example.trip_service.dto.TripEvent;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
class MatchingService {
  private static final Logger logger = LoggerFactory.getLogger(MatchingService.class);
  private final NotificationGrpcClient notificationClient;
  private final GeoOperations<String, String> geoOps;
  private final ObjectMapper objectMapper = new ObjectMapper();

  @KafkaListener(topics = "trip-events")
  @Async("threadPoolTaskExecutor")
  public void listenForTripEvent(TripEvent tripEvent) throws JsonMappingException, JsonProcessingException {
    logger.info("MatchingService received trip events");
    TripLocationData data = objectMapper.readValue(tripEvent.getData(), TripLocationData.class);
    List<Long> driverIdList = findNearbyAvailableDrivers(
        data.sourceLat(),
        data.sourceLng(), 
        5,
        10);

    if(driverIdList.isEmpty()) {
      logger.info("No driver is free right now");
    }

    for (Long driverId : driverIdList) {
      logger.info("Sending notification to driver {}", driverId);
      sendNotificationAsync(driverId, tripEvent.getTripId());
    }
  }

  @Async
  private void sendNotificationAsync(Long driverId, Long tripId) {
    try {
      notificationClient.sendNotification(
          driverId,
          "New Trip Offer",
          "Do you wanna take the trip: " + tripId + " ?");
      logger.info("Sent notification to driver {}", driverId);
    } catch (Exception e) {
      logger.error("Failed to send notification to driver {}: {}", driverId, e.getMessage());
    }
  }

  private List<Long> findNearbyAvailableDrivers(double lat, double lng, int limit, double radiusKm) {
    // Geo search
    Circle circle = new Circle(
        new Point(lng, lat),
        new Distance(radiusKm, Metrics.KILOMETERS));

    GeoResults<GeoLocation<String>> results = geoOps.radius("drivers:geo:free", circle);
    logger.info("GeoResults's size: {}", results.getContent().size());
    
    return results.getContent().stream()
        .map(result -> {
          String driverIdStr = result.getContent().getName();
          Long driverId = Long.valueOf(driverIdStr);
          return driverId;
        })
        .limit(limit)
        .collect(Collectors.toList());
  }

}

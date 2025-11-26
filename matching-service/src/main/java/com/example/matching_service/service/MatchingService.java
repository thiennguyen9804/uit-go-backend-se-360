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
import org.springframework.data.redis.connection.RedisGeoCommands.GeoRadiusCommandArgs;
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
  private final RedisTemplate<String, String> redisTemplate;
  private final ObjectMapper objectMapper = new ObjectMapper();

  @KafkaListener(topics = "trip-events")
  @Async("threadPoolTaskExecutor")
  public void listenForTripEvent(TripEvent tripEvent) throws JsonMappingException, JsonProcessingException {
    logger.info("MatchingService received trip events");
    TripLocationData tripData = objectMapper.readValue(tripEvent.getData(), TripLocationData.class);
    // logger.info("TripLocationData: {}", data.toString());
    List<String> driverIdList = findNearbyAvailableDrivers(
        tripData.sourceLat(),
        tripData.sourceLng(),
        5,
        10.0d);

    if(driverIdList.isEmpty()) {
      logger.info("No driver is free right now");
    }

    for (String driverId : driverIdList) {
      sendNotificationAsync(driverId, tripEvent.getTripId());
    }
  }

  @Async
  private void sendNotificationAsync(String driverId, Long tripId) {
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

  private List<String> findNearbyAvailableDrivers(double lat, double lng, int limit, double radiusKm) {
    // Geo search
    Circle circle = new Circle(
        new Point(lng, lat),
        new Distance(radiusKm, Metrics.KILOMETERS)
    );
    GeoRadiusCommandArgs args = GeoRadiusCommandArgs
      .newGeoRadiusArgs()
      .sortAscending()
      .limit(5);

    GeoResults<GeoLocation<String>> results = geoOps.radius("drivers:geo:free", circle, args);
    
    var driverIdList =  results.getContent().stream()
        .map(result -> {
          String driverIdStr = result.getContent().getName();
          return driverIdStr;
        })
        .collect(Collectors.toList());

    return driverIdList;
  }

}

package com.example.trip_service.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import org.springframework.data.geo.Point;
import org.springframework.data.redis.core.GeoOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import com.example.trip_service.client.NotificationGrpcClient;
import com.example.trip_service.dto.CreateTripRequest;
import com.example.trip_service.dto.FareRequest;
import com.example.trip_service.dto.FareResponse;
import com.example.trip_service.dto.TripDto;
import com.example.trip_service.dto.TripEvent;
import com.example.trip_service.dto.TripLocationData;
import com.example.trip_service.entity.TripEntity;
import com.example.trip_service.entity.TripEventEntity;
import com.example.trip_service.entity.TripEntity.TripStatus;
import com.example.trip_service.exception.TripAlreadyTakenException;
import com.example.trip_service.mapper.TripExtension;
import com.example.trip_service.repository.TripEventRepository;
import com.example.trip_service.repository.TripRepository;

import lombok.RequiredArgsConstructor;
import lombok.experimental.ExtensionMethod;
import tools.jackson.databind.ObjectMapper;

@Service
@ExtensionMethod({
    TripExtension.class
})
@RequiredArgsConstructor
public class TripService {
  private final TripRepository tripRepository;
  private final KafkaTemplate<String, TripEvent> kafkaTemplate;
  private final TripEventRepository eventRepository;
  private final ObjectMapper objectMapper = new ObjectMapper();
  private final RedisTemplate<String, String> redisTemplate;
  private final GeoOperations<String, String> geoOps;
  private final NotificationGrpcClient notificationClient;

  public FareResponse calculateFare(FareRequest request) {
    return new FareResponse(new BigDecimal(0));
  }

  public TripDto createTrip(CreateTripRequest request) {
    TripEntity tripEntity = TripEntity.builder()
        .riderId(request.riderId())
        .sourceLat(request.sourceLat())
        .sourceLng(request.sourceLng())
        .destLat(request.destLat())
        .destLng(request.destLng())
        .fare(request.fare())
        .status(TripEntity.TripStatus.PENDING)
        .build();

    TripLocationData data = new TripLocationData(
        request.sourceLat(),
        request.sourceLng(),
        request.destLat(),
        request.destLng());
    String dataAsString = objectMapper.writeValueAsString(data);

    tripEntity = tripRepository.save(tripEntity);
    TripEventEntity eventEntity = TripEventEntity.builder()
        .tripId(tripEntity.getId())
        .eventType("TRIP_CREATED")
        .data(dataAsString)
        .build();

    eventRepository.save(eventEntity);
    TripEvent avroEvent = TripEvent.newBuilder()
        .setId(System.currentTimeMillis())
        .setTripId(tripEntity.getId())
        .setEventType("TRIP_CREATED")
        .setData(dataAsString)
        .setCreatedAt(Instant.now())
        .build();
    kafkaTemplate.send("trip-events", String.valueOf(tripEntity.getId()), avroEvent);

    return tripEntity.toDto();
  }

  public TripDto getTrip(Long id) {
    return tripRepository.findById(id).get().toDto();
  }

  public TripDto cancelTrip(Long id, Long userId) {
    return new TripDto(userId, userId, userId, 0, 0, 0, 0, null, null, null, null);
  }

  public TripDto acceptTrip(Long tripId, Long driverId) {
    String lockKey = "trip:lock:" + tripId;
    String lockValue = UUID.randomUUID().toString(); // Giá trị độc nhất
    boolean acquired = false;
    String driverIdStr = driverId.toString();
    try {
      // 1. Thử lấy lock (SETNX + EXPIRE)
      acquired = redisTemplate.opsForValue()
          .setIfAbsent(lockKey, lockValue, 30, TimeUnit.SECONDS);
      if (!acquired) {
        throw new TripAlreadyTakenException("Chuyến đã được nhận bởi tài xế khác");
      }
      // 2. Kiểm tra Redis
      List<Point> posList = geoOps.position("drivers:geo:free", driverIdStr);
      var pos = posList.getFirst();

      // 3. Chuyển GeoSet
      geoOps.remove("drivers:geo:free", driverIdStr);
      geoOps.add("drivers:geo:intrip", new Point(pos.getX(), pos.getY()), driverIdStr);

      // 4. Cập nhật DB
      TripEntity trip = tripRepository.findById(tripId).get();
      trip.setDriverId(driverId);
      trip.setStatus(TripStatus.ACCEPTED);
      tripRepository.save(trip);

      // 5. Gửi thông báo tới rider
      notificationClient.sendNotification(
        trip.getRiderId(), 
        "Tài xế với id: " + driverId.toString() + " đã nhận cuốc xe!", 
        driverIdStr
      );
      
      return trip.toDto();

    } finally {
      // 6. Xóa lock nếu là owner
      if (acquired) {
        String currentValue = redisTemplate.opsForValue().get(lockKey);
        if (lockValue.equals(currentValue)) { // Kiểm tra owner
          redisTemplate.delete(lockKey);
        }
      }
    }
    // return new TripDto(driverId, driverId, driverId, 0, 0, 0, 0, null, null, null, null);
  }

}

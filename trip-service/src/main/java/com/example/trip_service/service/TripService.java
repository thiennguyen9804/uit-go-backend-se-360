package com.example.trip_service.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import com.example.trip_service.dto.StopMatchingCommand;
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
  private final KafkaTemplate<String, TripEvent> tripKafkaTemplate;
  private final KafkaTemplate<String, StopMatchingCommand> matchingKafkaTemplate;
  private final TripEventRepository eventRepository;
  private final ObjectMapper objectMapper = new ObjectMapper();
  private final RedisTemplate<String, String> redisTemplate;
  private final GeoOperations<String, String> geoOps;
  private final NotificationGrpcClient notificationClient;
  private final TripEventRepository tripEventRepository;
  private final Logger log = LoggerFactory.getLogger(this.getClass().getName());

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
        .createdAt(LocalDateTime.now())
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
    tripKafkaTemplate.send("trip-created-events", String.valueOf(tripEntity.getId()), avroEvent);

    return tripEntity.toDto();
  }

  public TripDto getTrip(Long id) {
    return tripRepository.findById(id).get().toDto();
  }

  public TripDto cancelTrip(Long id, String userId) {
    TripEntity trip = tripRepository.findById(id).get();
    if (trip.getStatus() == TripStatus.CANCELLED) {
      log.info("Trip {} đã được hủy trước đó bởi rider {}", id, userId);
      return trip.toDto();
    }
    TripStatus oldStatus = trip.getStatus();
    trip.setStatus(TripStatus.CANCELLED);
    trip.setCancelledAt(LocalDateTime.now());
    tripRepository.save(trip);
    log.info("Trip {} đã được hủy bởi rider {}. Trạng thái cũ: {}", id, userId, oldStatus);
    // if (oldStatus == TripStatus.PENDING) {
    //   StopMatchingCommand stopCmd = new StopMatchingCommand(id);
    //   matchingKafkaTemplate.send("stop-matching-commands", stopCmd);
    //   log.info("Đã gửi StopMatchingCommand cho trip {}", id);
    // }
    if (oldStatus == TripStatus.ACCEPTED || oldStatus == TripStatus.ONGOING) {

      notificationClient.sendNotification(
          trip.getDriverId(),
          "Chuyến đi bị hủy",
          "Khách đã hủy chuyến #" + id + ". Lý do: ");
    }

    // TripEvent cancelledEvent = TripEvent.newBuilder()
    //     .setId(System.currentTimeMillis())
    //     .setTripId(id)
    //     .setEventType("TRIP_CANCELLED")
    //     .setCreatedAt(Instant.now())
    //     .build();
    // tripKafkaTemplate.send("trip-cancelled-events", String.valueOf(id), cancelledEvent);
    return trip.toDto();

    // TripEvent tripEvent = tripEventRepository.findByTr
  }

  public TripDto acceptTrip(Long tripId, String driverId) {
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
          driverIdStr);

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
    // return new TripDto(driverId, driverId, driverId, 0, 0, 0, 0, null, null,
    // null, null);
  }

}

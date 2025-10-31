package com.example.matching_service.service;


import java.math.BigDecimal;
import java.time.Instant;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import com.example.matching_service.dto.CreateTripRequest;
import com.example.matching_service.dto.FareRequest;
import com.example.matching_service.dto.FareResponse;
import com.example.matching_service.dto.TripDto;
import com.example.matching_service.dto.TripLocationData;
import com.example.matching_service.entity.TripEntity;
import com.example.matching_service.entity.TripEventEntity;
import com.example.matching_service.mapper.TripExtension;
import com.example.matching_service.repository.TripEventRepository;
import com.example.matching_service.repository.TripRepository;
import com.example.trip_service.dto.TripEvent;

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
    return new TripDto(userId, userId, userId, null, null, null, null, null, null, null, null);
  }

  public TripDto acceptTrip(Long id, Long driverId) {
    return new TripDto(driverId, driverId, driverId, null, null, null, null, null, null, null, null);
  }

}

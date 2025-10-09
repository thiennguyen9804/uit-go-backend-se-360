package com.example.microservices.service;

import java.math.BigDecimal;
import java.time.Instant;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import com.example.microservices.entity.*;
import com.example.microservices.mapper.TripExtension;
import com.example.microservices.repository.TripEventRepository;
import com.example.microservices.repository.TripRepository;

import lombok.experimental.ExtensionMethod;

import com.example.microservices.dto.CreateTripRequest;
import com.example.microservices.dto.FareRequest;
import com.example.microservices.dto.FareResponse;
import com.example.microservices.dto.TripDto;
import com.example.microservices.dto.TripEvent;

@Service
@ExtensionMethod({ TripExtension.class })
public class TripService {
  private TripRepository tripRepository;
  private KafkaTemplate<String, TripEvent> kafkaTemplate;
  private TripEventRepository eventRepository;

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

    tripEntity = tripRepository.save(tripEntity);
    TripEventEntity eventEntity = TripEventEntity.builder()
        .tripId(tripEntity.getId())
        .eventType("TRIP_CREATED")
        .data("{\"message\": \"Trip created for rider " + request.riderId() + "\"}")
        .build();

    eventRepository.save(eventEntity);
    TripEvent avroEvent = TripEvent.newBuilder()
        .setId(System.currentTimeMillis())
        .setTripId(tripEntity.getId())
        .setEventType("TRIP_CREATED")
        // .setData("{\"message\": \"Trip created for rider " + request.riderId() +
        // "\"}")
        // .setCreatedAt(Instant.now().toEpochMilli())
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

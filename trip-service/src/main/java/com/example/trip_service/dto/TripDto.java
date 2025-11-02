package com.example.trip_service.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.example.trip_service.entity.TripEntity.TripStatus;

public record TripDto(
    Long id,
    Long riderId,
    Long driverId,
    double sourceLat,
    double sourceLng,
    double destLat,
    double destLng,
    BigDecimal fare,
    TripStatus status,
    LocalDateTime createdAt,
    LocalDateTime updatedAt) {
}

package com.example.matching_service.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.example.matching_service.entity.TripEntity.TripStatus;

public record TripDto(
    Long id,
    Long riderId,
    Long driverId,
    BigDecimal sourceLat,
    BigDecimal sourceLng,
    BigDecimal destLat,
    BigDecimal destLng,
    BigDecimal fare,
    TripStatus status,
    LocalDateTime createdAt,
    LocalDateTime updatedAt) {
}

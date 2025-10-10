package com.example.microservices.mapper;

import com.example.microservices.dto.TripDto;
import com.example.microservices.entity.TripEntity;

public class TripExtension {
  public static TripDto toDto(TripEntity tripEntity) {

    return new TripDto(
        tripEntity.getId(),
        tripEntity.getRiderId(),
        tripEntity.getDriverId(),
        tripEntity.getSourceLat(),
        tripEntity.getSourceLng(),
        tripEntity.getDestLat(),
        tripEntity.getDestLng(),
        tripEntity.getFare(),
        tripEntity.getStatus(),
        tripEntity.getCreatedAt(),
        tripEntity.getUpdatedAt());

  }
}

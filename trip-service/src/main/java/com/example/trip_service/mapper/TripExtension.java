package com.example.trip_service.mapper;

import com.example.trip_service.dto.TripDto;
import com.example.trip_service.entity.TripEntity;

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

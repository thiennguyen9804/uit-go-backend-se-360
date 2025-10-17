package com.example.matching_service.mapper;

import com.example.matching_service.dto.TripDto;
import com.example.matching_service.entity.TripEntity;

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

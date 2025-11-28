package com.example.trip_service.repository;


import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.trip_service.entity.TripEventEntity;


public interface TripEventRepository extends JpaRepository<TripEventEntity, Long> {
    Optional<TripEventEntity> findByTripId(Long tripId);
}

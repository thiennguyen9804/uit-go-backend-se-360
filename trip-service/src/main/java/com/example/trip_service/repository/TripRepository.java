package com.example.trip_service.repository;


import org.springframework.data.jpa.repository.JpaRepository;

import com.example.trip_service.entity.TripEntity;


public interface TripRepository extends JpaRepository<TripEntity, Long> {
}

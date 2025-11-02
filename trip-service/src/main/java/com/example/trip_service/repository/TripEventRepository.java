package com.example.trip_service.repository;


import org.springframework.data.jpa.repository.JpaRepository;

import com.example.trip_service.entity.TripEventEntity;


public interface TripEventRepository extends JpaRepository<TripEventEntity, Long> {
}

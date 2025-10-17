package com.example.matching_service.repository;


import org.springframework.data.jpa.repository.JpaRepository;

import com.example.matching_service.entity.TripEntity;


public interface TripRepository extends JpaRepository<TripEntity, Long> {
}

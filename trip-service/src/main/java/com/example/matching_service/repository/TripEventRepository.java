package com.example.matching_service.repository;


import org.springframework.data.jpa.repository.JpaRepository;

import com.example.matching_service.entity.TripEventEntity;


public interface TripEventRepository extends JpaRepository<TripEventEntity, Long> {
}

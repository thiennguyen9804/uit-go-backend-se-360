package com.example.microservices.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.microservices.entity.TripEventEntity;

public interface TripEventRepository extends JpaRepository<TripEventEntity, Long> {
}

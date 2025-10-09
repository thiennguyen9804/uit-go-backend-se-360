package com.example.microservices.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.microservices.entity.TripEntity;

public interface TripRepository extends JpaRepository<TripEntity, Long> {
}

package com.example.matching_service.dto;


public record TripLocationData(
    double sourceLat,
    double sourceLng,
    double destLat,
    double destLng
) {}
package com.example.matching_service.dto;

import java.math.BigDecimal;

public record TripLocationData(
    double sourceLat,
    double sourceLng,
    double destLat,
    double destLng) {
}
package com.example.trip_service.dto;

import java.math.BigDecimal;

public record CreateTripRequest(
        String riderId,
        double sourceLat,
        double sourceLng,
        double destLat,
        double destLng,
        BigDecimal fare) {
}

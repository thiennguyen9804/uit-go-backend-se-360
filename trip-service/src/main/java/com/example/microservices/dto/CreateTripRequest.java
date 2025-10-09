package com.example.microservices.dto;

import java.math.BigDecimal;

public record CreateTripRequest(
    Long riderId,
    BigDecimal sourceLat,
    BigDecimal sourceLng,
    BigDecimal destLat,
    BigDecimal destLng,
    BigDecimal fare) {
}

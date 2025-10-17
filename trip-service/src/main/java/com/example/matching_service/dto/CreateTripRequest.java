package com.example.matching_service.dto;

import java.math.BigDecimal;

public record CreateTripRequest(
    Long riderId,
    BigDecimal sourceLat,
    BigDecimal sourceLng,
    BigDecimal destLat,
    BigDecimal destLng,
    BigDecimal fare) {
}

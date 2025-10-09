package com.example.microservices.dto;

public record FareRequest(
    String source,
    String destination) {
}

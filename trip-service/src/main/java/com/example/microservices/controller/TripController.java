package com.example.microservices.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;
import com.example.microservices.dto.*;
import com.example.microservices.service.TripService;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/trips")
public class TripController {
  private TripService tripService;

  @GetMapping("/fare")
  public ResponseEntity<FareResponse> calculateFare(@ModelAttribute FareRequest request) {
    return ResponseEntity.ok(tripService.calculateFare(request));
  }

  @PostMapping
  public ResponseEntity<TripDto> createTrip(@RequestBody CreateTripRequest request) {
    return ResponseEntity.ok(tripService.createTrip(request));
  }

  @GetMapping("/{id}")
  public ResponseEntity<TripDto> getTrip(@PathVariable Long id) {
    return ResponseEntity.ok(tripService.getTrip(id));
  }

  @PostMapping("/{id}/cancel")
  public ResponseEntity<TripDto> cancelTrip(@PathVariable Long id, Long userId) {
    return ResponseEntity.ok(tripService.cancelTrip(id, userId));
  }

  @PutMapping("/{id}/accept")
  public ResponseEntity<TripDto> acceptTrip(@PathVariable Long id, Long driverId) {
    return ResponseEntity.ok(tripService.acceptTrip(id, driverId));
  }
}

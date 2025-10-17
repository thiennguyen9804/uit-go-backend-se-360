package com.example.matching_service.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.example.matching_service.dto.CreateTripRequest;
import com.example.matching_service.dto.FareRequest;
import com.example.matching_service.dto.FareResponse;
import com.example.matching_service.dto.TripDto;
import com.example.matching_service.service.TripService;

import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/trips")
@RequiredArgsConstructor
public class TripController {
  private final TripService tripService;

  @GetMapping("/hello")
  @ResponseStatus(code = HttpStatus.ACCEPTED)
  public String sayHello() {
    return "Hello from Trip Service!!!";
  }

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

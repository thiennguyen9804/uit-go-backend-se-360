package com.example.trip_service.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.*;

import com.example.trip_service.dto.CreateTripRequest;
import com.example.trip_service.dto.DriverAcceptRequest;
import com.example.trip_service.dto.FareRequest;
import com.example.trip_service.dto.FareResponse;
import com.example.trip_service.dto.TripDto;
import com.example.trip_service.service.TripService;

@RestController
@RequestMapping("/api/trips")
@RequiredArgsConstructor
public class TripController {
  private final TripService tripService;

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
  public ResponseEntity<TripDto> cancelTrip(@PathVariable Long id, String userId) {
    return ResponseEntity.ok(tripService.cancelTrip(id, userId));
  }

  @PutMapping("/{id}/accept")
  public ResponseEntity<TripDto> acceptTrip(@PathVariable Long id, @RequestBody DriverAcceptRequest request)  {
    var driverId = request.driverId();
    return ResponseEntity.ok(tripService.acceptTrip(id, driverId));
  }
}



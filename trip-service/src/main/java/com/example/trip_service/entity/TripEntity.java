package com.example.trip_service.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "trips")
@Data
@Builder
public class TripEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "rider_id")
  private Long riderId;

  @Column(name = "driver_id")
  private Long driverId;

  @Column(name = "source_lat", nullable = false, precision = 9)
  private double sourceLat;

  @Column(name = "source_lng", nullable = false, precision = 9)
  private double sourceLng;

  @Column(name = "dest_lat", nullable = false, precision = 9)
  private double destLat;

  @Column(name = "dest_lng", nullable = false, precision = 9)
  private double destLng;

  @Column(name = "fare", nullable = false, precision = 10, scale = 2)
  private BigDecimal fare;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", length = 20, nullable = false)
  @Builder.Default
  private TripStatus status = TripStatus.PENDING;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;

  @UpdateTimestamp
  @Column(name = "updated_at", nullable = false)
  private LocalDateTime updatedAt;

  // Enum for status
  public enum TripStatus {
    PENDING, ACCEPTED, ONGOING, COMPLETED, CANCELLED
  }
}

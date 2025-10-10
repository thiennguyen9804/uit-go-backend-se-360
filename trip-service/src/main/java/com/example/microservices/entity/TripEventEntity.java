package com.example.microservices.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "trip_events")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TripEventEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "trip_id", nullable = false)
  private Long tripId;

  @Column(name = "event_type", length = 50)
  private String eventType;

  @Column(name = "data", columnDefinition = "nvarchar(max)")
  private String data;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;
}

package com.example.notification_service.entity;

import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Builder;
import lombok.Data;

@Entity
@Table(name = "device_tokens")
@Data
@Builder
public class DeviceToken {
  @Id
  private String userId;
  private String fcmToken;

  @UpdateTimestamp
  private long lastUpdated;
}

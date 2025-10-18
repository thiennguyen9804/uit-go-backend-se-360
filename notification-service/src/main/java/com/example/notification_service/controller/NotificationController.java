package com.example.notification_service.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.notification_service.dto.DeviceRegistrationRequest;
import com.example.notification_service.service.NotificationService;

import lombok.RequiredArgsConstructor;

/**
 * NotificationController
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {
  private final NotificationService notificationService;

  @PostMapping("/register-instance")
  @ResponseStatus(code = HttpStatus.OK)
  public void registerInstance(@RequestBody DeviceRegistrationRequest request) {
    notificationService.saveToken(request.userId(), request.fcmToken());
  }
}

package com.example.notification_service;

import java.io.IOException;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication
public class NotificationServiceApplication {
  public static void main(String[] args) throws IOException, InterruptedException {
    SpringApplication.run(NotificationServiceApplication.class, args);
    // Server server = ServerBuilder
    //     .forPort(28084)
    //     .build();
    // server.start();
    // server.awaitTermination();
  }

}

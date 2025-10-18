package com.example.notification_service.config;

import java.io.IOException;
import java.io.InputStream;

import javax.annotation.PostConstruct;

import org.springframework.context.annotation.Configuration;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

/**
 * FirebaseConfig
 */
@Configuration
public class FirebaseConfig {
  @PostConstruct
  public void initialize() throws IOException {
    InputStream serviceAccount = getClass()
        .getClassLoader()
        .getResourceAsStream("firebase-service-account.json");
    if (serviceAccount == null) {
      throw new IOException("Service account file not found");
    }
    FirebaseOptions options = FirebaseOptions.builder()
        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
        .build();

    if (FirebaseApp.getApps().isEmpty()) {
      FirebaseApp.initializeApp(options);
    }
  }

}

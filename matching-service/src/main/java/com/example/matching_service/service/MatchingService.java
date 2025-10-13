package com.example.matching_service.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import lombok.extern.java.Log;
import com.example.matching_service.dto.TripEvent;

@Service
class MatchingService {
  private static final Logger logger = LoggerFactory.getLogger(MatchingService.class);

  @KafkaListener(topics = "trip-events")
  public void listen(TripEvent tripEvent) {
    logger.info("MatchingService received trip events");
  }
}

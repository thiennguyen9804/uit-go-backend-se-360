package com.example.trip_service.exception;

public class TripNotFoundException extends RuntimeException {
    public TripNotFoundException() {
        super();
    }

    public TripNotFoundException(String message) {
        super(message);
    }
}

package com.example.trip_service.exception;

public class TripAlreadyTakenException extends RuntimeException {
    public TripAlreadyTakenException() {
        super();
    }

    public TripAlreadyTakenException(String message) {
        super(message);
    }
}

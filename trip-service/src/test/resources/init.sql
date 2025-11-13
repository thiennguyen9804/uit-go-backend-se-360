-- init.sql
CREATE TABLE Trips (
    id BIGINT PRIMARY KEY,
    riderId BIGINT,
    sourceLat FLOAT,
    sourceLng FLOAT,
    destLat FLOAT,
    destLng FLOAT,
    fare DECIMAL(10,2),
    status VARCHAR(20),
    driverId BIGINT
);
INSERT INTO Trips (id, riderId, sourceLat, sourceLng, destLat, destLng, fare, status)
VALUES (1, 100, 10.762622, 106.660172, 10.771570, 106.698090, 50000, 'PENDING');
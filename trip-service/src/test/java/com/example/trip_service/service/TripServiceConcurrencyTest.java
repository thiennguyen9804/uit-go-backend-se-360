// package com.example.trip_service.service;

// import static org.assertj.core.api.Assertions.assertThat;
// import static org.mockito.ArgumentMatchers.any;
// import static org.mockito.ArgumentMatchers.anyLong;
// import static org.mockito.ArgumentMatchers.anyString;
// import static org.mockito.Mockito.times;
// import static org.mockito.Mockito.verify;
// import static org.mockito.Mockito.when;

// import java.math.BigDecimal;
// import java.util.Optional;
// import java.util.concurrent.CountDownLatch;
// import java.util.concurrent.ExecutorService;
// import java.util.concurrent.Executors;
// import java.util.concurrent.TimeUnit;
// import java.util.concurrent.atomic.AtomicInteger;

// import org.junit.After;
// import org.junit.AfterClass;
// import org.junit.Before;
// import org.junit.BeforeClass;
// import org.junit.ClassRule;
// import org.junit.Test;
// import org.junit.jupiter.api.DisplayName;
// import org.junit.jupiter.api.extension.ExtendWith;
// import org.junit.runner.RunWith;
// import org.junit.runners.JUnit4;
// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.boot.test.context.SpringBootTest;
// import org.springframework.boot.test.mock.mockito.MockBean;
// import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
// import org.springframework.data.geo.Point;
// import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
// import org.springframework.data.redis.connection.lettuce.LettuceConnection;
// import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
// import org.springframework.data.redis.core.GeoOperations;
// import org.springframework.data.redis.core.RedisTemplate;
// import org.springframework.kafka.core.KafkaTemplate;
// import org.springframework.test.context.bean.override.mockito.MockitoBean;
// import org.springframework.test.context.junit.jupiter.SpringExtension;
// import org.springframework.test.context.junit4.SpringRunner;
// import org.testcontainers.containers.GenericContainer;
// import org.testcontainers.mssqlserver.MSSQLServerContainer;
// import org.testcontainers.junit.jupiter.Container;
// import org.testcontainers.junit.jupiter.Testcontainers;

// import com.example.trip_service.client.NotificationGrpcClient;
// import com.example.trip_service.dto.TripEvent;
// import com.example.trip_service.entity.TripEntity;
// import com.example.trip_service.entity.TripEntity.TripStatus;
// import com.example.trip_service.exception.TripAlreadyTakenException;
// import com.example.trip_service.repository.TripEventRepository;
// import com.example.trip_service.repository.TripRepository;

// @SpringBootTest
// @Testcontainers
// public class TripServiceConcurrencyTest {

//     @Container
//     @ServiceConnection
//     static final GenericContainer<?> redis = new GenericContainer<>("redis:7.0-alpine")
//             .withExposedPorts(6379);

//     private RedisTemplate<String, String> redisTemplate = new RedisTemplate<>();

//     // @Autowired
//     private GeoOperations<String, String> geoOps;

//     @MockitoBean
//     private TripRepository tripRepository;

//     @MockitoBean
//     private KafkaTemplate<String, TripEvent> kafkaTemplate;

//     @MockitoBean
//     private TripEventRepository eventRepository;

//     @MockitoBean
//     private NotificationGrpcClient notificationClient;

//     private TripService tripService;

//     @Before
//     public void setUp() {
       
//         geoOps = redisTemplate.opsForGeo();
//         tripService = new TripService(
//                 tripRepository,
//                 kafkaTemplate,
//                 eventRepository,
//                 redisTemplate,
//                 geoOps,
//                 notificationClient);

//     }

//     @After
//     public void tearDown() {
//         // Clear Redis trước mỗi test
//         redisTemplate.getConnectionFactory().getConnection().flushAll();
//     }

//     @Test
//     public void acceptTrip_ThrowsException_WhenTripAlreadyTaken() throws InterruptedException {
//         // Given
//         Long tripId = 1L;
//         Long driver1 = 100L;
//         Long driver2 = 200L;
//         Long riderId = 300L;

//         // Setup both drivers in Redis
//         geoOps.add("drivers:geo:free", new Point(106.6297, 10.8231), driver1.toString());
//         geoOps.add("drivers:geo:free", new Point(106.6300, 10.8230), driver2.toString());

//         TripEntity trip = TripEntity.builder()
//                 .id(tripId)
//                 .riderId(riderId)
//                 .sourceLat(10.8231)
//                 .sourceLng(106.6297)
//                 .destLat(10.7769)
//                 .destLng(106.7009)
//                 .fare(new BigDecimal("50000"))
//                 .status(TripStatus.PENDING)
//                 .build();

//         when(tripRepository.findById(tripId)).thenReturn(Optional.of(trip));
//         when(tripRepository.save(any(TripEntity.class))).thenAnswer(i -> i.getArgument(0));

//         CountDownLatch latch = new CountDownLatch(1);
//         AtomicInteger successCount = new AtomicInteger(0);
//         AtomicInteger failCount = new AtomicInteger(0);

//         // When - 2 drivers đồng thời accept cùng 1 trip
//         ExecutorService executor = Executors.newFixedThreadPool(2);

//         executor.submit(() -> {
//             try {
//                 latch.await();
//                 tripService.acceptTrip(tripId, driver1);
//                 successCount.incrementAndGet();
//             } catch (TripAlreadyTakenException e) {
//                 failCount.incrementAndGet();
//             } catch (Exception e) {
//                 // ignore
//             }
//         });

//         executor.submit(() -> {
//             try {
//                 latch.await();
//                 tripService.acceptTrip(tripId, driver2);
//                 successCount.incrementAndGet();
//             } catch (TripAlreadyTakenException e) {
//                 failCount.incrementAndGet();
//             } catch (Exception e) {
//                 // ignore
//             }
//         });

//         latch.countDown(); // Start both threads
//         executor.shutdown();
//         executor.awaitTermination(10, TimeUnit.SECONDS);

//         // Then - Chỉ 1 driver thành công, 1 driver fail
//         assertThat(successCount.get()).isEqualTo(1);
//         assertThat(failCount.get()).isEqualTo(1);

//         // Verify chỉ 1 driver được chuyển sang intrip
//         int driversInTrip = geoOps.position("drivers:geo:intrip", driver1.toString()).isEmpty() ? 0 : 1;
//         driversInTrip += geoOps.position("drivers:geo:intrip", driver2.toString()).isEmpty() ? 0 : 1;
//         assertThat(driversInTrip).isEqualTo(1);

//         // Verify notification chỉ gửi 1 lần
//         verify(notificationClient, times(1)).sendNotification(anyLong(), anyString(), anyString());
//     }


// }
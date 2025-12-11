import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { SharedArray, Atomic } from 'k6/data';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';


interface User {
  userId: string;
  email: string;
  jwt: string;
  isDriver?: boolean;
  driverId?: string;
}


// Đọc dữ liệu từ file seeding-data.json (đã có 70 user + 20 driver)
const seedingData = new SharedArray('seedingData', function () {
  const data = JSON.parse(open('./seeding-data.json'));
  const passengers = data.users.filter(u => !u.isDriver); // chỉ lấy passenger
  const drivers = data.users.filter(u => u.isDriver);    // 20 driver
  return [{ passengers, drivers }];
});

const pendingTrips = new SharedArray('pendingTrips', () => []);


const { passengers, drivers } = seedingData[0];

// Metrics
const errorRate = new Rate('errors');
const bookingDuration = new Trend('booking_duration');
const acceptDuration = new Trend('accept_duration');
const tripAcceptedRate = new Rate('trip_accepted');
const bookingSuccess = new Counter('successful_bookings');
const acceptSuccess = new Counter('successful_accepts');
const acceptConflict = new Counter('accept_conflicts'); // 409, 400

// Cấu hình test
export const options = {
  scenarios: {
    smoke_booking: {
      executor: 'shared-iterations',
      vus: 3,
      iterations: 3,
      exec: 'smokeBooking',
    },
    smoke_accept: {
      executor: 'constant-vus',
      vus: 20, // 20 driver cùng poll
      duration: '30s',
      exec: 'driverAcceptTrip',
      startTime: '5s',
    },
    // Load Test: Tạo tổng 1000 req trong 2'
    // load: {
    //   executor: 'constant-arrival-rate',
    //   rate: 8,              // 8 requests mỗi giây
    //   timeUnit: '1s',       // trong 1 giây
    //   duration: '2m',       // chạy trong 2 phút
    //   preAllocatedVUs: 20,  // Số VUs khởi tạo sẵn
    //   maxVUs: 50,           // Số VUs tối đa nếu cần
    //   tags: { test_type: 'load' },
    //   exec: 'loadTest',
    //   startTime: '30s',     // Bắt đầu sau smoke test
    // },
  },

  thresholds: {
    'http_req_duration': ['p(95)<2500'],
    'errors': ['rate<0.05'],
    'trip_accepted': ['rate>0.95'],  // >95% trip phải được tài xế nhận
  },
};

const BASE_URL = 'http://localhost:9000/api';

// Payload đặt xe cố định (có thể random sau)
const bookingPayload = {
  sourceLat: 10.782461,
  sourceLng: 106.643840,
  destLat: 10.780000,
  destLng: 106.705000,
  fare: 55000.0,
};

// Hàm đặt xe
function bookTrip(user: User) {
  const payload = JSON.stringify({
    ...bookingPayload,
    riderId: user.userId, // dùng userId thật từ seeding
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: { name: 'BookTrip' },
  };

  const start = Date.now();
  const res = http.post(`${BASE_URL}/trips`, payload, params);
  const duration = Date.now() - start;

  bookingDuration.add(duration);

  const success = res.status === 201 || res.status === 200;
  if (success) {
    const tripId = res.json().id as string;
    console.log(`Trip created: ${tripId} by ${user.email}`);

    // Giả lập: chọn ngẫu nhiên 3-5 driver gần nhất để offer
    const shuffled = drivers.sort(() => 0.5 - Math.random());
    const candidates = shuffled.slice(0, randomIntBetween(3, 5));

    // Lưu trip vào danh sách chờ accept
    pendingTrips.push({
      tripId,
      candidates: candidates.map(d => d.userId),
      accepted: false,
    });

    bookingSuccess.add(1);
  }
  const hasTripId = success && res.json().id !== undefined;

  // save trip id into list here

  const checks = {
    'status is 2xx': success,
    'has trip id': hasTripId,
    'response time < 3s': res.timings.duration < 3000,
  };
  const isError = !(checks['status is 2xx'] && checks['has trip id']);
  
  errorRate.add(isError);
  // bookingSuccessRate.add(success && hasTripId);

  if (isError) {
    console.error(`❌ Request ERROR: ${user.email}, Status: ${res.status}, Body: ${res.body}`);
  } else if (!check['response time < 3s']) {
    console.log(`⚠️  Slow response when creating trip id: ${res.json().id} - ${user.email}`);
  }

  return res;
}

function tryAcceptTrip(driver) {
  let accepted = false;

  for (let i = 0; i < pendingTrips.length; i++) {
    const trip = pendingTrips[i];

    // Kiểm tra xem driver này có trong danh sách được offer không
    if (!trip.candidates.includes(driver.userId)) continue;
    if (trip.accepted) continue; // đã có người accept rồi

    // Dùng atomic để lock trip này
    if (Atomic.increment(`lock_${trip.tripId}`, 1) > 0) continue; // đã bị lock

    // Gọi API accept
    const res = http.put(`${BASE_URL}/trips/${trip.tripId}/accept`, JSON.stringify({
      driverId: driver.userId
    }), {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driver.jwt}`,
      },
    });

    if (res.status === 200 || res.status === 201) {
      console.log(`Driver ${driver.email} ACCEPTED trip ${trip.tripId}`);
      trip.accepted = true;
      acceptSuccess.add(1);
      accepted = true;
    } else {
      console.warn(`Driver ${driver.email} FAILED to accept trip ${trip.tripId} - Status: ${res.status}`);
      acceptConflict.add(1);
    }

    // Unlock
    Atomic.decrement(`lock_${trip.tripId}`, 1);
    break; // chỉ thử 1 trip mỗi lần poll
  }

  return accepted;
}

// === FULL FLOW: Đặt xe + Chờ offer + Accept ===
export function fullBookingFlow(passenger: User) {

  // B1: Đặt xe
  const result = bookTrip(passenger);
  if (!result) {
    sleep(1);
    return;
  }

  const { tripId } = result;

  // B2: Giả lập hệ thống đã gửi offer tới 3–5 driver gần nhất
  // (trong thực tế: backend sẽ gửi FCM, ở đây ta giả lập bằng cách random chọn)
  const numOffered = 3 + Math.floor(Math.random() * 3); // 3–5 drivers
  const shuffledDrivers = drivers
    // .sort(() => 0.5 - Math.random());
  const offeredDrivers = shuffledDrivers.slice(0, numOffered);

  // B3: Chờ 2–5s như thật (tài xế đang xem offer)
  sleep(2 + Math.random() * 3);

  // B4: 1 trong số driver accept
  acceptTrip(tripId, offeredDrivers);

  // Nghỉ ngơi trước iteration tiếp theo
  sleep(1);
}

// Smoke Test: 3 người đặt xe
export function smokeBooking() {
  const user = passengers[__VU % passengers.length];
  bookTrip(user);
  sleep(1);
}
// Load Test: 1000+ lượt đặt xe
// export function loadTest() {
//   const user = seedingData[__VU % seedingData.length];
//   fullBookingFlow(user);
//   sleep(Math.random() * 2 + 0.5); // giống người thật
// }

export function driverAcceptTrip() {
  const driver = drivers[__VU % drivers.length];
  tryAcceptTrip(driver);
  sleep(0.5); // poll mỗi 0.5s
}

// Summary đẹp
export function handleSummary(data) {
  const successCount = data.metrics.booking_success?.values?.count || 0;
  const totalReqs = data.metrics.http_reqs?.values?.count || 0;

  return {
    'stdout': `
════════════════════════════════════════════════
     K6 - BOOKING TEST SUMMARY (UIT-Go)
════════════════════════════════════════════════
Scenarios:       Smoke (3 bookings) + Load (1000+ bookings)
Total Requests:  ${totalReqs}
Avg Response:    ${(data.metrics.http_req_duration?.values?.avg || 0).toFixed(2)}ms
p95 Response:    ${(data.metrics.http_req_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
Error Rate:      ${((data.metrics.errors?.values?.rate || 0)*100).toFixed(2)}%
Bookings Created:     ${bookingSuccess.value}
Trips Accepted:       ${acceptSuccess.value}
Accept Conflicts:     ${acceptConflict.value}
Success Rate:         ${((acceptSuccess.value / bookingSuccess.value) * 100).toFixed(1)}%
════════════════════════════════════════════════
    `,
    'k6-summary.json': JSON.stringify(data, null, 2),
  };
}
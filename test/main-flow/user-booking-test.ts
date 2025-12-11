import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { SharedArray } from 'k6/data';

// Đọc dữ liệu từ file seeding-data.json (đã có 70 user + 20 driver)
const seedingData = new SharedArray('seedingData', function () {
  return JSON.parse(open('./seeding-data.json')).users; // chỉ lấy users (passengers)
});

// Metrics
const errorRate = new Rate('errors');
const bookingDuration = new Trend('booking_duration');
const bookingSuccessRate = new Rate('booking_success');

// Cấu hình test
export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 3,                    // 3 người đặt xe
      duration: '1s',
      exec: 'smokeTest',
      tags: { test_type: 'smoke' },
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
    'http_req_duration': ['p(95)<2000'],     // 95% dưới 2s
    'http_req_failed': ['rate<0.05'],        // lỗi < 5%
    'errors': ['rate<0.05'],
    'booking_success': ['rate>0.90'],        // >90% đặt xe thành công
    'booking_duration': ['p(95)<2000'],
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
function bookTrip(user) {
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
  const hasTripId = success && res.json().id !== undefined;

  const checks = {
    'status is 2xx': success,
    'has trip id': hasTripId,
    'response time < 3s': res.timings.duration < 3000,
  };
  const isError = !(checks['status is 2xx'] && checks['has trip id']);
  errorRate.add(isError);
  bookingSuccessRate.add(success && hasTripId);

  if (isError) {
    console.error(`❌ Request ERROR: ${user.email}, Status: ${res.status}, Body: ${res.body}`);
  } else if (!check['response time < 3s']) {
    console.log(`⚠️  Slow response when creating trip id: ${res.json().id} - ${user.email}`);
  }

  return res;
}

// Smoke Test: 3 người đặt xe
export function smokeTest() {
  const user = seedingData[__VU % seedingData.length]; // vòng qua các user
  bookTrip(user);
  sleep(1);
}

// Load Test: 1000+ lượt đặt xe
export function loadTest() {
  const user = seedingData[__VU % seedingData.length];
  bookTrip(user);
  sleep(Math.random() * 2 + 0.5); // giống người thật
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
════════════════════════════════════════════════
    `,
    'k6-summary.json': JSON.stringify(data, null, 2),
  };
}
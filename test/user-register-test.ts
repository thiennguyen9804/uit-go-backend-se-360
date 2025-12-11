import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const registerDuration = new Trend('register_duration');

// Test configuration
export const options = {
  scenarios: {
    // Smoke Test: 5 users trong 1 phút
    smoke: {
      executor: 'constant-vus',
      vus: 5,
      duration: '1m',
      tags: { test_type: 'smoke' },
      exec: 'smokeTest',
    },
    
    // Load Test: Tạo tổng 7000 user trong 5'
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 20 },   // Ramp up to 20 users
        { duration: '2m', target: 100 },  // Ramp up to 100 users
        { duration: '1m', target: 100 },  // Stay at 100 users
        { duration: '1m', target: 0 },    // Ramp down to 0 users
      ],
      tags: { test_type: 'load' },
      exec: 'loadTest',
      startTime: '1m', // Bắt đầu sau smoke test
    },


    // Load Test: Tạo tổng 1000 user trong 2'
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
  
  // Thresholds - Điều kiện pass/fail
  thresholds: {
    'http_req_duration': ['p(95)<500'], // 95% requests < 500ms
    'http_req_failed': ['rate<0.01'],   // Error rate < 1%
    'errors': ['rate<0.01'],
    'register_duration': ['p(95)<500'],
  },
};

// Base URL
const BASE_URL = 'http://localhost:9000/api';

// Generate random email
function generateEmail(): string {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  return `user_${timestamp}_${random}@test.com`;
}

// Generate strong password (uppercase, lowercase, number, special char)
function generatePassword(): string {
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const numbers = '0123456789';
  const special = '!@#$%^&*';
  
  let password = '';
  
  // Đảm bảo có ít nhất 1 ký tự mỗi loại
  password += uppercase.charAt(Math.floor(Math.random() * uppercase.length));
  password += lowercase.charAt(Math.floor(Math.random() * lowercase.length));
  password += numbers.charAt(Math.floor(Math.random() * numbers.length));
  password += special.charAt(Math.floor(Math.random() * special.length));
  
  // Thêm các ký tự random để đủ 12 ký tự
  const allChars = uppercase + lowercase + numbers + special;
  for (let i = password.length; i < 12; i++) {
    password += allChars.charAt(Math.floor(Math.random() * allChars.length));
  }
  
  // Shuffle password
  return password.split('').sort(() => Math.random() - 0.5).join('');
}
// Register user function
function registerUser() {
  const payload = JSON.stringify({
    email: generateEmail(),
    password: generatePassword(),
  });
  
  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: { name: 'RegisterUser' },
  };
  
  const startTime = Date.now();
  const response = http.post(`${BASE_URL}/user/register`, payload, params);
  const duration = Date.now() - startTime;
  
  // Record custom metrics
  registerDuration.add(duration);
  
  // Checks với detailed validation
  const checks = {
    'status is 200 or 201': response.status === 200 || response.status === 201,
    'response has body': response.body && response.body.length > 0,
    'response time < 500ms': response.timings.duration < 500,
  };
  
  const checkResult = check(response, checks);
  
  // Track errors (chỉ khi status code thất bại)
  const isError = !(checks['status is 200 or 201'] && checks['response has body']);
  errorRate.add(isError);
  
  // Log chi tiết khi có vấn đề
  if (isError) {
    console.error(`❌ Request ERROR - Status: ${response.status}, Duration: ${response.timings.duration.toFixed(2)}ms, Body: ${response.body}`);
  } else if (!checks['response time < 500ms']) {
    console.warn(`⚠️  Slow response - Duration: ${response.timings.duration.toFixed(2)}ms (threshold: 500ms)`);
  }
  
  return response;
}

// Smoke Test - Kiểm tra API hoạt động cơ bản
export function smokeTest() {
  registerUser();
  sleep(1); // Đợi 1 giây giữa các requests
}

// Load Test - Test với tải bình thường
export function loadTest() {
  registerUser();
  sleep(Math.random() * 2 + 0.5); // Random sleep 0.5-2.5s để giống real users
}

// Summary handler
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'summary.json': JSON.stringify(data),
  };
}

// Helper function for text summary
function textSummary(data, options) {
  const indent = options?.indent || '';
  const enableColors = options?.enableColors || false;
  
  let summary = '\n';
  summary += `${indent}════════════════════════════════════════════════════\n`;
  summary += `${indent}📊 K6 PERFORMANCE TEST SUMMARY\n`;
  summary += `${indent}════════════════════════════════════════════════════\n\n`;
  
  // Scenarios
  summary += `${indent}🎯 Scenarios:\n`;
  Object.entries(data.root_group.groups).forEach(([name, group]: [string, any]) => {
    summary += `${indent}  - ${name}: ${group.checks.passes}/${group.checks.fails + group.checks.passes} checks passed\n`;
  });
  
  summary += `\n${indent}📈 Metrics:\n`;
  
  // HTTP metrics
  const metrics = data.metrics;
  if (metrics.http_req_duration) {
    summary += `${indent}  HTTP Request Duration:\n`;
    summary += `${indent}    - avg: ${metrics.http_req_duration.values.avg.toFixed(2)}ms\n`;
    summary += `${indent}    - min: ${metrics.http_req_duration.values.min.toFixed(2)}ms\n`;
    summary += `${indent}    - max: ${metrics.http_req_duration.values.max.toFixed(2)}ms\n`;
    summary += `${indent}    - p95: ${metrics.http_req_duration.values['p(95)'].toFixed(2)}ms\n`;
  }
  
  if (metrics.http_req_failed) {
    const failRate = (metrics.http_req_failed.values.rate * 100).toFixed(2);
    summary += `${indent}  Error Rate: ${failRate}%\n`;
  }
  
  if (metrics.http_reqs) {
    summary += `${indent}  Total Requests: ${metrics.http_reqs.values.count}\n`;
    summary += `${indent}  Requests/sec: ${metrics.http_reqs.values.rate.toFixed(2)}\n`;
  }
  
  summary += `\n${indent}════════════════════════════════════════════════════\n`;
  
  return summary;
}
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration');

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
    
    // Load Test: 100 users trong 5 phút
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 20 },
        { duration: '2m', target: 100 },
        { duration: '1m', target: 100 },
        { duration: '1m', target: 0 },
      ],
      tags: { test_type: 'load' },
      exec: 'loadTest',
      startTime: '1m',
    },
  },
  
  thresholds: {
    'http_req_duration': ['p(95)<500'],
    'http_req_failed': ['rate<0.01'],
    'errors': ['rate<0.01'],
    'login_duration': ['p(95)<500'],
  },
};

const BASE_URL = 'http://localhost:9000/api';

// Danh sách users để test login
const TEST_USERS = [
  { email: 'test1@example.com', password: 'Test123!@#' },
  { email: 'test2@example.com', password: 'Test123!@#' },
  { email: 'test3@example.com', password: 'Test123!@#' },
  { email: 'test4@example.com', password: 'Test123!@#' },
  { email: 'test5@example.com', password: 'Test123!@#' },
  { email: 'test6@example.com', password: 'Test123!@#' },
  { email: 'test7@example.com', password: 'Test123!@#' },
  { email: 'test8@example.com', password: 'Test123!@#' },
  { email: 'test9@example.com', password: 'Test123!@#' },
  { email: 'test10@example.com', password: 'Test123!@#' },
];

// Setup function - Chạy 1 lần duy nhất trước khi bắt đầu test
export function setup() {
  console.log('🌱 Seeding test users...');
  
  let successCount = 0;
  let skipCount = 0;
  
  for (let i = 0; i < TEST_USERS.length; i++) {
    const user = TEST_USERS[i];
    
    const payload = JSON.stringify({
      email: user.email,
      password: user.password,
    });
    
    const params = {
      headers: {
        'Content-Type': 'application/json',
      },
    };
    
    const response = http.post(`${BASE_URL}/user/login`, payload, params);
    
    if (response.status === 200 || response.status === 201) {
      console.log(`✅ Created user: ${user.email}`);
      successCount++;
    } else if (response.status === 409 || response.status === 400) {
      // User đã tồn tại - OK
      console.log(`⏭️  User already exists: ${user.email}`);
      skipCount++;
    } else {
      console.error(`❌ Failed to create user: ${user.email}, Status: ${response.status}, Body: ${response.body}`);
    }
    
    // Đợi một chút giữa các request để tránh overwhelm API
    sleep(0.2);
  }
  
  console.log(`\n📊 Seeding summary:`);
  console.log(`   - Created: ${successCount} users`);
  console.log(`   - Skipped (already exists): ${skipCount} users`);
  console.log(`   - Total: ${successCount + skipCount}/${TEST_USERS.length} users ready\n`);
  
  // Đợi 2 giây để API ổn định trước khi bắt đầu test
  sleep(2);
  
  return { usersReady: true };
}

// Lấy random user từ danh sách
function getRandomUser() {
  const index = Math.floor(Math.random() * TEST_USERS.length);
  return TEST_USERS[index];
}

// Login function
function loginUser() {
  const user = getRandomUser();
  
  const payload = JSON.stringify({
    email: user.email,
    password: user.password,
  });
  
  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: { name: 'LoginUser' },
  };
  
  const startTime = Date.now();
  const response = http.post(`${BASE_URL}/user/login`, payload, params);
  const duration = Date.now() - startTime;
  
  // Record custom metrics
  loginDuration.add(duration);
  
  // Checks với detailed validation
  const checks = {
    'status is 200': response.status === 200,
    'response has body': response.body && response.body.length > 0,
    'response time < 500ms': response.timings.duration < 500,
    'has token or session': (r) => {
      try {
        const body = JSON.parse(r.body);
        // Kiểm tra response có chứa token hoặc session data
        return body.token || body.accessToken || body.jwt || body.id;
      } catch {
        return false;
      }
    },
  };
  
  const checkResult = check(response, checks);
  
  // Track errors (chỉ khi login thất bại)
  const isError = !(checks['status is 200'] && checks['response has body']);
  errorRate.add(isError);
  
  // Log chi tiết khi có vấn đề
  if (isError) {
    console.error(`❌ Login ERROR - Email: ${user.email}, Status: ${response.status}, Body: ${response.body}`);
  } else if (!checks['response time < 500ms']) {
    console.warn(`⚠️  Slow login - Duration: ${response.timings.duration.toFixed(2)}ms (threshold: 500ms)`);
  } else if (!checks['has token or session']) {
    console.warn(`⚠️  Login success but no token found - Email: ${user.email}, Body: ${response.body}`);
  }
  
  return response;
}

// Smoke Test
export function smokeTest() {
  loginUser();
  sleep(1);
}

// Load Test
export function loadTest() {
  loginUser();
  // Không cần sleep vì constant-arrival-rate tự động điều chỉnh
}

// Teardown function - Chạy 1 lần sau khi test xong (optional)
export function teardown(data) {
  console.log('\n✅ Test completed!');
  if (data.usersReady) {
    console.log('📝 Note: Test users remain in database for future tests');
    console.log('   To clean up, manually delete users with email pattern: test*@example.com');
  }
}

// Summary handler
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'summary.json': JSON.stringify(data),
  };
}

function textSummary(data, options) {
  const indent = options?.indent || '';
  
  let summary = '\n';
  summary += `${indent}════════════════════════════════════════════════════\n`;
  summary += `${indent}📊 K6 LOGIN PERFORMANCE TEST SUMMARY\n`;
  summary += `${indent}════════════════════════════════════════════════════\n\n`;
  
  summary += `${indent}🎯 Scenarios:\n`;
  Object.entries(data.root_group.groups).forEach(([name, group]: [string, any]) => {
    summary += `${indent}  - ${name}: ${group.checks.passes}/${group.checks.fails + group.checks.passes} checks passed\n`;
  });
  
  summary += `\n${indent}📈 Metrics:\n`;
  
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
  
  if (metrics.login_duration) {
    summary += `\n${indent}  Login Duration:\n`;
    summary += `${indent}    - avg: ${metrics.login_duration.values.avg.toFixed(2)}ms\n`;
    summary += `${indent}    - p95: ${metrics.login_duration.values['p(95)'].toFixed(2)}ms\n`;
  }
  
  summary += `\n${indent}════════════════════════════════════════════════════\n`;
  
  return summary;
}
import axios from 'axios';
import fs from 'fs';
import path from 'path';

const BASE_URL = 'http://localhost:9000/api';
const TOTAL_USERS = 70;
const USER_PASSWORD = 'Test123!@#';
const ADMIN_EMAIL = 'admin@uitgo.com';
const ADMIN_PASSWORD = 'Admin@123';
const DRIVERS_TO_CREATE = 20; // Số tài xế cần tạo

interface User {
  userId: string;
  email: string;
  jwt: string;
  isDriver?: boolean;
  driverId?: string;
}

interface SeedingResult {
  users: User[];
  drivers: User[]; // Danh sách tài xế đã được duyệt
  admin: {
    jwt: string;
  };
}

const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// === Các hàm cũ (giữ nguyên) ===
async function registerUser(email: string, password: string): Promise<string> {
  try {
    const response = await api.post('/user/register', { email, password });
    console.log(`Registered: ${email}`);
    return response.data.id;
  } catch (error: any) {
    if (error.response?.status === 409 || error.response?.data?.message?.includes('already exists')) {
      console.log(`Already exists (skip register): ${email}`);
      return 'skip';
    }
    throw new Error(`Register failed for ${email}: ${error.response?.data || error.message}`);
  }
}

async function loginUser(email: string, password: string): Promise<{ userId: string; jwt: string }> {
  try {
    const response = await api.post('/user/login', { email, password });
    const userId = response.data.user.id;
    const jwt = response.data.token;
    if (!userId || !jwt) throw new Error('Missing userId or token');
    return { userId, jwt };
  } catch (error: any) {
    throw new Error(`Login failed for ${email}: ${error.response?.data || error.message}`);
  }
}

async function loginAdmin(): Promise<string> {
  const response = await api.post('/user/login', {
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
  });
  return response.data.token;
}

// === MỚI: Đăng ký làm tài xế ===
async function registerAsDriver(user: User): Promise<void> {
  const payload = {
    vehicleType: "SmallCar",
    phoneNumber: `090${Math.floor(1000000 + Math.random() * 9000000)}`,
    vehicleNumber: `51H-${Math.floor(10000 + Math.random() * 90000)}`,
    name: `Driver ${user.email.split('@')[0]}`,
  };

  try {
    await api.post('/user/driver-register', payload, {
      headers: { Authorization: `Bearer ${user.jwt}` },
    });
    console.log(`Đã đăng ký làm tài xế: ${user.email}`);
    // user.isDriver = true;
  } catch (error: any) {
    if (error.response?.status === 400 && error.response?.data?.message?.includes('already')) {
      console.log(`Đã là tài xế rồi: ${user.email}`);
      // user.isDriver = true;
    } else {
      throw error;
    }
  }
}

// === MỚI: Admin duyệt tài xế ===
async function approveDriver(driverRegistrationId: string, adminJwt: string): Promise<void> {
  try {
    await api.put(`/user/driver-register/${driverRegistrationId}`, {
      "status": "Approved"
    }, {
      headers: { Authorization: `Bearer ${adminJwt}` },
    });
    console.log(`Admin đã duyệt tài xế: ${driverRegistrationId}`);
  } catch (error: any) {
    if (error.response?.status === 400 && error.response?.data?.message?.includes('already')) {
      console.log(`Tài xế đã được duyệt rồi: ${driverRegistrationId}`);
    } else {
      throw error;
    }
  }
}

// === THÊM: Lấy danh sách các đơn đăng ký tài xế (pending) ===
async function getPendingDriverRegistrations(adminJwt: string): Promise<any[]> {
  try {
    const response = await api.get('/user/driver-register/all', {
      headers: { Authorization: `Bearer ${adminJwt}` },
      params: {
        Status: 'Pending',
        Page: 1,
        Size: 20,
      },
    },);
    // Lọc chỉ những cái đang Pending
    return response.data.data
  } catch (error: any) {
    console.error('Lỗi lấy danh sách đăng ký tài xế:', error.response?.data || error.message);
    return [];
  }
}

// === MỚI: Tài xế bật trạng thái đang làm việc ===
async function enableWorkingState(driver: User): Promise<void> {
  try {
    await api.put('/drivers/driver-state/working-state', 
      { enabled: true },
      { headers: { Authorization: `Bearer ${driver.jwt}` } }
    );
    console.log(`Tài xế online: ${driver.email}`);
  } catch (error: any) {
    if (error.response?.data?.message?.includes('already')) {
      console.log(`Đã online rồi: ${driver.email}`);
    } else {
      console.warn(`Lỗi bật trạng thái làm việc ${driver.email}:`, error.response?.data || error.message);
    }
  }
}

// === MỚI: Tài xế cập nhật vị trí GPS ===
async function updateDriverLocation(driver: User): Promise<void> {
  // Khu vực TP.HCM: lat ~10.73 -> 10.80, long ~106.63 -> 106.73
  const lat = 10.73 + Math.random() * 0.07;
  const lng = 106.63 + Math.random() * 0.10;

  try {
    await api.post('/drivers/driver-state/location',
      { latitude: lat, longitude: lng },
      { headers: { Authorization: `Bearer ${driver.jwt}` } }
    );
    console.log(`Cập nhật vị trí: ${driver.email} → (${lat.toFixed(6)}, ${lng.toFixed(6)})`);
  } catch (error: any) {
    console.warn(`Lỗi cập nhật vị trí ${driver.email}:`, error.response?.data || error.message);
  }
}

// === MỚI: Đăng ký FCM Instance ID cho tài xế (để nhận thông báo cuốc xe) ===
async function registerFcmTokenForDriver(driver: User): Promise<void> {
  const FIXED_FCM_TOKEN = "";
  const payload = {
    userId: driver.userId,
    fcmToken: FIXED_FCM_TOKEN,
  };

  try {
    await api.post('/notifications/register-instance', payload);
    console.log(`Đã đăng ký FCM token cho tài xế: ${driver.email}`);
  } catch (error: any) {
    if (error.response?.status === 409 || error.response?.data?.message?.includes('already')) {
      console.log(`FCM token đã được đăng ký trước đó: ${driver.email}`);
    } else {
      console.warn(`Lỗi đăng ký FCM cho ${driver.email}:`, error.response?.data || error.message);
    }
  }
}

// === MAIN ===
async function main() {
  const filePath = path.join(process.cwd(), 'seeding-data.json');
  let data: SeedingResult = { users: [], drivers: [], admin: { jwt: '' } };

  // Bước 1: Đọc file nếu đã có (tránh tạo lại 70 user)
  if (fs.existsSync(filePath)) {
    console.log('Đọc dữ liệu từ seeding-data.json...');
    data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    console.log(`Đã load ${data.users.length} users và admin JWT`);
  } else {
    // Nếu chưa có thì tạo mới 70 user như cũ
    console.log('Không tìm thấy file → tạo mới 70 user...');
    for (let i = 1; i <= TOTAL_USERS; i++) {
      const email = `test${i}@example.com`;
      await registerUser(email, USER_PASSWORD);
      const { userId, jwt } = await loginUser(email, USER_PASSWORD);
      data.users.push({ userId, email, jwt });
      await delay(200);
    }
    data.admin.jwt = await loginAdmin();

  }

  // Đảm bảo admin JWT luôn có
  if (!data.admin.jwt) {
    console.log('Đăng nhập lại admin...');
    data.admin.jwt = await loginAdmin();
  }
  // fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');


  // Bước 2: Lấy 20 user đầu tiên làm tài xế
  const driverCandidates = data.users.slice(0, DRIVERS_TO_CREATE);
  for (const user of driverCandidates) {
    await registerAsDriver(user);
    await delay(300);
  }


  // === BƯỚC 3: Admin lấy danh sách các đơn đăng ký đang Pending ===
  console.log('\nAdmin đang lấy danh sách đơn đăng ký tài xế...');
  const pendingRegistrations = await getPendingDriverRegistrations(data.admin.jwt);
  for (const reg of pendingRegistrations) {
    const driverRegistrationId = reg.id; // Đây mới là Id đúng để duyệt!
    await approveDriver(driverRegistrationId, data.admin.jwt);
    await delay(400);

    // Gán cờ isDriver cho user tương ứng (để lần sau không làm lại)
    const matchedUser = data.users.find(u => u.userId === reg.userId);
    if (matchedUser) {
      matchedUser.isDriver = true;
    }
  }

  // Cập nhật danh sách drivers
  data.drivers = data.users.filter(u => u.isDriver);

  // Lưu lại file (có thêm drivers)
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');

  // INSERT YOUR CODE HERE
  console.log('\nBắt đầu bật trạng thái làm việc và cập nhật vị trí cho các tài xế...');

  // Lấy danh sách tài xế đã được duyệt (có isDriver = true)
  const approvedDrivers = data.users.filter(u => u.isDriver);

  if (approvedDrivers.length === 0) {
    console.warn('Không tìm thấy tài xế nào đã được duyệt!');
  } else {
    console.log(`Tìm thấy ${approvedDrivers.length} tài xế đã duyệt → bật online và cập nhật vị trí...`);

    for (const driver of approvedDrivers) {
      // 1. Bật trạng thái làm việc
      await enableWorkingState(driver);
      await delay(300);

      // 2. Cập nhật vị trí hiện tại (1 lần đầu tiên)
      await updateDriverLocation(driver);
      await delay(300);
    }

    console.log(`\nHOÀN TẤT! ${approvedDrivers.length} tài xế đã:`);
    console.log('   • Được duyệt');
    console.log('   • Đã bật trạng thái làm việc (online)');
    console.log('   • Đã cập nhật vị trí GPS (trong TP.HCM)');
    console.log('   → Sẵn sàng nhận cuốc xe từ hành khách!');
  }

  // insert code here
  console.log('\nBắt đầu đăng ký FCM Instance ID cho các tài xế (để nhận thông báo đặt xe)...');

  if (data.drivers.length === 0) {
    console.warn('Không có tài xế nào để đăng ký FCM!');
  } else {
    for (const driver of data.drivers) {
      await registerFcmTokenForDriver(driver);
      await delay(300); // nhẹ nhàng với server
    }

    console.log(`\nHOÀN TẤT! Đã đăng ký FCM token cho ${data.drivers.length} tài xế`);
    console.log('→ Bây giờ tài xế sẽ nhận được thông báo khi có cuốc xe mới!');
  }

  console.log('\nHOÀN TẤT TOÀN BỘ SEEDING!');
  console.log(`Tổng user: ${data.users.length}`);
  console.log(`Tài xế đã duyệt: ${data.drivers.length}`);
  console.log(`File đã được cập nhật: ${filePath}`);
  console.log('\nSẵn sàng dùng cho k6 test đặt xe rồi đó!');
}

main().catch(err => {
  console.error('Lỗi:', err.response?.data || err.message);
  process.exit(1);
});
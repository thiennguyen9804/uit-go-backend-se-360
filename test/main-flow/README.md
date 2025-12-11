# Hệ thống Test Đặt Xe (Grab/Uber-like) - Flow Seeding & Load Test

Dự án này giúp bạn **chuẩn bị dữ liệu thật** và **test hiệu năng** cho hệ thống đặt xe với:
- 70 người dùng (passenger)
- 20 tài xế được duyệt, online, có vị trí GPS và nhận được FCM notification
- k6 script smoke test + load test đặt xe thật

---

### Yêu cầu trước khi chạy

1. Backend đang chạy tại: `http://localhost:9000`
2. Các docker service hoạt động bình thường
3. Node.js ≥ 18 đã cài
4. k6 đã cài[](https://k6.io/docs/getting-started/installation/)

---

### Bước 1: Cài đặt dependencies

```bash
# Tạo thư mục và vào đó
cd test/main-flow

# Init project
npm init -y
npm install axios typescript ts-node @types/node

# Tạo tsconfig (nếu chưa có)
npx tsc --init
```


### Bước 2: Chạy Seeding – Chuẩn bị dữ liệu thật (CHỈ CẦN CHẠY 1 LẦN DUY NHẤT)

```bash
npx tsx src/index.ts
```

### 3. Chạy test thật
> **Lưu ý quan trọng:** Hiện tại trong file `k6-booking-test.js`, phần **Load Test đã bị comment** (chỉ còn Smoke Test chạy được).  
> Nếu bạn muốn bật Load Test → bỏ comment phần `load` trong `scenarios` (xem hướng dẫn bên dưới).
```bash
k6 run k6-booking-test.js
```



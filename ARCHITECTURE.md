# 📚 TÀI LIỆU KIẾN TRÚC HỆ THỐNG GỌI XE CÔNG NGHỆ

---

## 🧩 1. Giới Thiệu & Tổng Quan (Overview / Introduction)

Hệ thống là một nền tảng **Dịch vụ Theo Yêu cầu (On-Demand Service)**, được triển khai theo **kiến trúc Microservices**.  
Mục tiêu chính là xây dựng một nền tảng **ổn định**, **mở rộng cao (Scalable)** và **hiệu suất vượt trội** trong xử lý **giao dịch thời gian thực (Real-time Transaction)**.

### 🎯 Mục Tiêu Chính

- **Scalability:** Dễ dàng mở rộng ngang cho các dịch vụ đòi hỏi hiệu suất cao như `Match-service`.  
- **Performance:** Tối ưu hóa độ trễ (latency) trong việc tìm kiếm và ghép nối tài xế lân cận.  
- **Reliability:** Đảm bảo tính chịu lỗi thông qua giao tiếp bất đồng bộ (`Kafka` / `Event Hubs`) và cơ chế `Event Sourcing`.  

---

## 🗺 2. Sơ Đồ Ngữ Cảnh & Tổng Thể (System Context Diagram - C4 Level 1)

Hệ thống bao gồm các thành phần chính:

- **Rider/Driver App:** Là ứng dụng di động của người dùng và tài xế. Tất cả yêu cầu đều được gửi qua **API Gateway**.  
- **API Gateway:** Là điểm truy cập duy nhất của hệ thống, chịu trách nhiệm xử lý định tuyến và xác thực (`Auth/Auth`). Gateway giao tiếp với các dịch vụ nội bộ qua `REST` hoặc `gRPC`.  
- **Các Microservice cốt lõi:** Bao gồm `Trip`, `Match`, `Driver`, và `User`. Các dịch vụ này giao tiếp nội bộ bằng `gRPC` và bất đồng bộ qua `Kafka`.  
- **MSSQL:** Lưu trữ dữ liệu giao dịch quan trọng như người dùng, tài xế, và lịch sử chuyến đi.  
- **Redis:** Quản lý dữ liệu thời gian thực như vị trí tài xế (Geospatial) và khóa tranh chấp chuyến đi.  
- **Kafka/Event Hubs:** Đóng vai trò message broker, chịu trách nhiệm truyền tải sự kiện bất đồng bộ giữa các service.

---

## ⚙️ 3. Thành Phần Cốt Lõi (Core Components / Modules)

Hệ thống gồm các microservice chính, mỗi service chịu trách nhiệm cho một phần nghiệp vụ:

- **User-service:**  
  Được xây dựng bằng **ASP.NET Core**, có nhiệm vụ quản lý tài khoản người dùng, đăng ký, đăng nhập, xác thực và phân quyền.  
  Giao tiếp qua `gRPC`, `REST`, và kết nối với cơ sở dữ liệu `MSSQL`.

- **Driver-service:**  
  Phát triển bằng **Spring Boot**, quản lý thông tin tài xế và trạng thái làm việc.  
  Mọi thay đổi trạng thái được ghi lại bằng **Event Sourcing** thông qua sự kiện `DriverWorkStatusEvent`.  
  Service này giao tiếp nội bộ qua `gRPC` và lưu dữ liệu trên `MSSQL`.

- **Trip-service:**  
  Cũng được phát triển bằng **Spring Boot**, quản lý toàn bộ vòng đời của chuyến đi — từ tạo mới, cập nhật trạng thái, đến kết thúc.  
  Dịch vụ này sử dụng mô hình **Event Sourcing** (với bảng `trip_events`) và đẩy sự kiện lên `Kafka`.  
  Giao tiếp qua `gRPC` và kết nối với `MSSQL`.

- **Match-service:**  
  Được viết bằng **Spring Boot**, đảm nhiệm logic tìm kiếm và ghép nối tài xế gần nhất.  
  Dịch vụ sử dụng **Redis Geospatial Query** để truy vấn nhanh các vị trí lân cận.  
  Giao tiếp nội bộ qua `gRPC` và kết nối `Redis`.

- **Notification-service:**  
  (Dự kiến) được xây dựng bằng **Node.js**, có nhiệm vụ lắng nghe các sự kiện từ `Kafka` và gửi thông báo real-time đến ứng dụng di động thông qua **Firebase Cloud Messaging (FCM)**.

---


## 🧱 4. Lưu Trữ Dữ Liệu & Lược Đồ (Data Storage & Schema)

### 4.1. Dữ liệu Quan hệ (MSSQL Server)

Hệ thống sử dụng **MSSQL Server** cho các dịch vụ yêu cầu tính toàn vẹn cao:

- `User-service` lưu trữ thông tin người dùng trong bảng `ApplicationUser` và hồ sơ tài xế chờ duyệt trong bảng `DriverRegister`.  
- `Driver-service` lưu thông tin tài xế trong bảng `Driver` và ghi nhận các sự kiện làm việc trong bảng `DriverWorkStatusEvent`.  
- `Trip-service` lưu dữ liệu chuyến đi trong bảng `trips` và các sự kiện liên quan trong `trip_events`.

### 4.2. Dữ liệu Real-time (Redis)

Redis được sử dụng để xử lý dữ liệu real-time và các truy vấn vị trí hiệu suất cao:

- Dữ liệu vị trí tài xế rảnh được lưu trong **`driver:geo:free`** dưới dạng **GeoSet**, phục vụ cho việc tìm kiếm tài xế gần nhất.  
- Dữ liệu vị trí tài xế đang trong chuyến đi được lưu trong **`driver:geo:intrip`** cũng dưới dạng **GeoSet**, giúp theo dõi di chuyển trong thời gian thực.  
- Mỗi chuyến đi được khóa bằng **`trip:lock:{tripId}`**, là một giá trị **String hoặc UUID**, đảm bảo chỉ một tài xế có thể nhận chuyến đi duy nhất (cơ chế **atomic operation**).

---


## 🔄 5. Luồng Dữ Liệu Chi Tiết (Data Flow / Sequence Diagrams)

### 🚕 Luồng Đặt Xe & Ghép Nối (Ride Request & Matching)

1. **Rider Request:** Rider App → API Gateway → Trip-service (tạo Trip ở trạng thái `PENDING`).  
2. **Geo Query:** Trip-service gọi Match-service (qua `gRPC`) để truy vấn tài xế rảnh từ `driver:geo:free`.  
3. **Dispatch:** Match-service gửi danh sách tài xế tiềm năng lên Kafka (`driver-candidates`).  
4. **Driver Notification:** Notification-service tiêu thụ sự kiện từ Kafka và gửi thông báo tới Driver App qua FCM.

### 🔐 Luồng Tài Xế Chấp Nhận & Khóa Chuyến Đi (Claim & Lock)

1. **Accept Request:** Driver App → API Gateway → Driver-service.  
2. **Atomic Lock:** Driver-service cố gắng đặt khóa `trip:lock:{tripId}` trong Redis.
   - ✅ Thành công → tài xế được gán.
   - ❌ Thất bại → chuyến đi đã bị tài xế khác bắt.  
3. **Trip Update:** Nếu khóa thành công → gọi Trip-service (`gRPC`) để cập nhật trạng thái sang `ACCEPTED`.  
4. **Event Notification:** Trip-service đẩy sự kiện `Trip Accepted` lên Kafka → Notification-service gửi thông báo cho Rider.  

---

## ⚡ 6. Khả Năng Mở Rộng & Độ Tin Cậy (Scalability & Reliability)

- **Horizontal Scaling:** Triển khai Microservices trên **Kubernetes (AKS)**, tự động scale Pod khi tải tăng.  
- **Tối ưu hóa Đọc:** Dùng **Read Replica** cho Azure SQL + **Azure Cache for Redis** để giảm tải cho Primary DB.  
- **Giao tiếp bất đồng bộ:** Dùng Kafka/Event Hubs để giảm áp lực giữa các service (chống backpressure).  
- **Kiểm thử hiệu năng:** Dùng **Azure Load Testing** để đánh giá khả năng chịu tải.  

---

## 🔐 7. Bảo Mật & Triển Khai (Security & Deployment)

### 7.1. Bảo Mật (Security)

- **Auth/Auth:** Thực hiện bởi `User-service` (ASP.NET Identity), xác thực token (JWT/Session) tại API Gateway.  
- **Giao tiếp:** Tất cả request dùng `HTTP` và `gRPC` (HTTP/2) để mã hóa dữ liệu.  

### 7.2. Triển Khai & CI/CD

...

---

## 🧠 8. Quyết Định Kiến Trúc Quan Trọng (Architecture Decision Records - ADR Summary)

- Hệ thống sử dụng **gRPC** để giao tiếp nội bộ giữa các service nhằm tối ưu hiệu suất và độ trễ nhờ HTTP/2 và Protobuf.  
- Các module `Trip` và `Driver` áp dụng **Event Sourcing**, giúp đảm bảo tính toàn vẹn dữ liệu và hỗ trợ xử lý bất đồng bộ qua Kafka.  
- **Redis Geospatial** được chọn để thực hiện các truy vấn vị trí real-time nhanh chóng, giảm tải cho cơ sở dữ liệu quan hệ.  



# ========================= 1. BUILDER STAGE =========================
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app

# Step 1: Copy file định nghĩa dependency trước → cache siêu mạnh
COPY pom.xml .
# (Nếu dùng multi-module thì copy thêm: COPY parent/pom.xml parent/ ...)

# Step 2: Tải dependency trước (layer này cache 99% thời gian)
# -B = batch mode, không hiện progress bar → CI/CD đẹp
RUN mvn dependency:go-offline -B

# Step 3: Copy source code (chỉ rebuild từ đây khi code đổi)
COPY src ./src

# Step 4: Build + tạo Layered JAR (thần thánh của Spring Boot 3.2+)
# --layers → tạo 4 layer: dependencies, spring-boot-loader, snapshot-dependencies, application
RUN mvn clean package -DskipTests -B \
    && java -Djarmode=tools -jar target/*.jar extract --layers --destination target/extracted

# ========================= 2. RUNTIME STAGE =========================
# Dùng BellSoft CDS → startup < 1 giây, RAM giảm 30–40%
FROM bellsoft/liberica-openjre-debian:21.0.8-cds AS final

WORKDIR /app

# Copy từng layer riêng → Docker cache thông minh cực đỉnh
COPY --from=builder /app/target/extracted/dependencies/ ./
COPY --from=builder /app/target/extracted/spring-boot-loader/ ./
COPY --from=builder /app/target/extracted/snapshot-dependencies/ ./
COPY --from=builder /app/target/extracted/application/ ./

# (Tùy chọn) Health check + expose port
EXPOSE 8081

# Chạy với JarLauncher → tận dụng layered JAR + CDS
ENTRYPOINT ["java", "-jar", "trip-service-0.0.1-SNAPSHOT.jar"]
# ========================= 1. BUILDER STAGE =========================
FROM maven:3.9.9-eclipse-temurin-11 AS builder
WORKDIR /app

# Copy pom.xml first for better caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build
RUN mvn clean package -DskipTests -B \
    && java -Djarmode=tools -jar target/*.jar extract --layers --destination target/extracted

# ========================= 2. RUNTIME STAGE =========================
FROM eclipse-temurin:11-jre AS final
WORKDIR /app

COPY --from=builder /app/target/extracted/dependencies/ ./
COPY --from=builder /app/target/extracted/spring-boot-loader/ ./
COPY --from=builder /app/target/extracted/snapshot-dependencies/ ./
COPY --from=builder /app/target/extracted/application/ ./

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "demo-service-0.0.1-SNAPSHOT.jar"]

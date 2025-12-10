# ========================= 1. BUILDER STAGE =========================
FROM maven:3.9.9-eclipse-temurin-11 AS builder
WORKDIR /app

# Copy pom.xml first for better caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build (skip tests for image build)
RUN mvn -B -ntp clean package -DskipTests

# ========================= 2. RUNTIME STAGE =========================
FROM eclipse-temurin:11-jre AS final
WORKDIR /app

# Copy fat jar
COPY --from=builder /app/target/*.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

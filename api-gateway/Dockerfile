# Stage 1: Build the application using Maven and Java 21
FROM maven:3.9.8-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run the built JAR using minimal base image
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app


# Copy the built JAR
COPY --from=builder /app/target/api-gateway-0.0.1-SNAPSHOT.jar app.jar

# Expose port
EXPOSE 9000


# Start Spring Boot app with production profile
ENTRYPOINT ["java", "-jar", "app.jar"]

# Stage 2: Build
FROM maven:3.9.8-eclipse-temurin-21 as build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 3: Production
FROM eclipse-temurin:21-jre-alpine as production
WORKDIR /app
COPY --from=build /app/target/matching-service-0.0.1-SNAPSHOT.jar /app/app.jar
EXPOSE 8083
CMD ["java", "-jar", "app.jar"]
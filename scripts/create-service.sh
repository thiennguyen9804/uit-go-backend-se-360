#!/bin/bash
# Script để tạo service mới từ template

set -euo pipefail

SERVICE_NAME=$1
LANGUAGE=${2:-"maven"}  # maven, dotnet, node, python, go

if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: ./scripts/create-service.sh <service-name> [language]"
  echo "Example: ./scripts/create-service.sh payment-service maven"
  exit 1
fi

# Validate service name format
if [[ ! "$SERVICE_NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "❌ Error: Service name must be lowercase, alphanumeric with hyphens only"
  echo "   Example: payment-service, user-api, notification-handler"
  exit 1
fi

SERVICE_DIR="$SERVICE_NAME"
TEMPLATE_DIR=".github/templates/service-template"

echo "🚀 Creating new service: $SERVICE_NAME"
echo "📦 Language: $LANGUAGE"
echo ""

# Check if service already exists
if [ -d "$SERVICE_DIR" ]; then
  echo "❌ Error: Service directory '$SERVICE_DIR' already exists!"
  exit 1
fi

# Create service directory
mkdir -p "$SERVICE_DIR"
cd "$SERVICE_DIR"

# Create service.yml
cat > service.yml <<EOF
service:
  name: "${SERVICE_NAME}"
  display_name: "${SERVICE_NAME^}"
  description: "Auto-generated ${SERVICE_NAME} service"
  version: "1.0.0"
  
  build:
    language: "${LANGUAGE}"
    dockerfile: "Dockerfile"
    
  runtime:
    port: 8080
    health_check_path: "/actuator/health"
    cpu: 0.5
    memory: "1.0Gi"
    min_replicas: 0
    max_replicas: 3
    
  networking:
    external: false
    
  dependencies:
    database: false
    kafka: false
    redis: false
    
  tags:
    team: "backend"
    environment: "dev"
    managed_by: "self-service-platform"
EOF

# Create language-specific files
case $LANGUAGE in
  maven)
    echo "📦 Creating Maven/Spring Boot service..."
    
    mkdir -p "src/main/java/com/example/${SERVICE_NAME}"
    mkdir -p "src/main/resources"
    mkdir -p "src/test/java/com/example/${SERVICE_NAME}"
    
    # Create pom.xml
    cat > pom.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>${SERVICE_NAME}</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>${SERVICE_NAME}</name>
    
    <properties>
        <java.version>21</java.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    # Create Dockerfile
    cat > Dockerfile <<'DOCKERFILE'
# ========================= 1. BUILDER STAGE =========================
FROM maven:3.9.9-eclipse-temurin-21 AS builder
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
FROM bellsoft/liberica-openjre-debian:21.0.8-cds AS final
WORKDIR /app

COPY --from=builder /app/target/extracted/dependencies/ ./
COPY --from=builder /app/target/extracted/spring-boot-loader/ ./
COPY --from=builder /app/target/extracted/snapshot-dependencies/ ./
COPY --from=builder /app/target/extracted/application/ ./

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "SERVICE_NAME-0.0.1-SNAPSHOT.jar"]
DOCKERFILE
    
    # Replace SERVICE_NAME in Dockerfile
    sed -i "s/SERVICE_NAME/${SERVICE_NAME}/g" Dockerfile
    
    # Create Spring Boot application
    APP_CLASS="${SERVICE_NAME^}Application"
    cat > "src/main/java/com/example/${SERVICE_NAME}/${APP_CLASS}.java" <<EOF
package com.example.${SERVICE_NAME};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ${APP_CLASS} {
    public static void main(String[] args) {
        SpringApplication.run(${APP_CLASS}.class, args);
    }
}
EOF

    # Create controller
    cat > "src/main/java/com/example/${SERVICE_NAME}/controller/HealthController.java" <<EOF
package com.example.${SERVICE_NAME}.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    @GetMapping("/actuator/health")
    public String health() {
        return "UP";
    }
}
EOF

    # Create application.yml
    cat > src/main/resources/application.yml <<EOF
server:
  port: 8080

spring:
  application:
    name: ${SERVICE_NAME}

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always
EOF
    ;;
    
  dotnet)
    echo "📦 Creating .NET service..."
    # TODO: Add .NET template
    ;;
    
  *)
    echo "⚠️  Language template for '$LANGUAGE' not fully implemented"
    echo "   Creating basic Dockerfile..."
    cat > Dockerfile <<EOF
FROM alpine:latest
WORKDIR /app
EXPOSE 8080
CMD ["echo", "Service ${SERVICE_NAME} - customize this Dockerfile"]
EOF
    ;;
esac

# Create README
cat > README.md <<EOF
# ${SERVICE_NAME^}

## Description
${SERVICE_NAME} service - Auto-generated by self-service platform

## Development

\`\`\`bash
# Run locally
# For Maven: mvn spring-boot:run
# For .NET: dotnet run

# Build
# For Maven: mvn clean package
# For .NET: dotnet build

# Test
# For Maven: mvn test
# For .NET: dotnet test
\`\`\`

## Configuration

Edit \`service.yml\` to configure:
- Runtime resources (CPU, memory, replicas)
- Dependencies (database, kafka, redis)
- Environment variables
- Networking settings

## Deployment

Service will be automatically deployed via GitHub Actions when you push to main branch.

To deploy manually:
1. Go to Actions -> Deploy Service -> Run workflow
2. Enter service name: \`${SERVICE_NAME}\`
3. Click Run workflow

## Health Check

Service exposes health endpoint at: \`/actuator/health\`

## Documentation

See [Self-Service Platform Guide](../../docs/SELF_SERVICE_GUIDE.md) for more information.
EOF

# Create .gitignore
cat > .gitignore <<EOF
# Build outputs
target/
bin/
obj/
*.jar
*.war

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
EOF

cd ..

echo ""
echo "✅ Service created successfully!"
echo ""
echo "📁 Service directory: $SERVICE_DIR"
echo "📝 Next steps:"
echo "   1. cd $SERVICE_DIR"
echo "   2. Review and customize service.yml"
echo "   3. Implement your service logic"
echo "   4. Test locally"
echo "   5. git add . && git commit -m 'feat: add $SERVICE_NAME' && git push"
echo ""


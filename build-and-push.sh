#!/bin/bash

# Script to build and push all microservice images to Azure Container Registry

ACR_NAME="acrrgmicroservicevn"
ACR_SERVER="${ACR_NAME}.azurecr.io"
PROJECT_ROOT="/home/duyan2509/se360/uit-go-backend-se-360"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building and pushing images to ${ACR_SERVER}...${NC}\n"

# Login to ACR
echo -e "${GREEN}Logging in to ACR...${NC}"
if docker info > /dev/null 2>&1; then
    # Try az acr login first
    if ! az acr login --name $ACR_NAME 2>/dev/null; then
        # If that fails, use token-based login
        echo -e "${YELLOW}Using token-based login...${NC}"
        TOKEN=$(az acr login --name $ACR_NAME --expose-token --query accessToken -o tsv 2>/dev/null)
        if [ -n "$TOKEN" ]; then
            echo "$TOKEN" | docker login $ACR_SERVER --username 00000000-0000-0000-0000-000000000000 --password-stdin
        else
            echo -e "${RED}Failed to get ACR token${NC}"
            exit 1
        fi
    fi
else
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# .NET services need to build from root (need proto-contracts)
dotnet_services=("user-service" "driver-service")

# Java services need to build from service directory (need pom.xml and src in context root)
java_services=("trip-service" "notification-service" "matching-service" "api-gateway")

# Build and push .NET services (from project root)
for service in "${dotnet_services[@]}"; do
    echo -e "\n${YELLOW}Building ${service} (from project root)...${NC}"
    
    docker build \
        -f "${PROJECT_ROOT}/${service}/Dockerfile" \
        -t "${ACR_SERVER}/${service}:latest" \
        "${PROJECT_ROOT}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${service} built successfully${NC}"
        
        echo -e "${YELLOW}Pushing ${service}...${NC}"
        docker push "${ACR_SERVER}/${service}:latest"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ ${service} pushed successfully${NC}"
        else
            echo -e "${RED}✗ Failed to push ${service}${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to build ${service}${NC}"
    fi
done

# Build and push Java services (from service directory)
for service in "${java_services[@]}"; do
    echo -e "\n${YELLOW}Building ${service} (from service directory)...${NC}"
    
    docker build \
        -f "${PROJECT_ROOT}/${service}/Dockerfile" \
        -t "${ACR_SERVER}/${service}:latest" \
        "${PROJECT_ROOT}/${service}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${service} built successfully${NC}"
        
        echo -e "${YELLOW}Pushing ${service}...${NC}"
        docker push "${ACR_SERVER}/${service}:latest"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ ${service} pushed successfully${NC}"
        else
            echo -e "${RED}✗ Failed to push ${service}${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to build ${service}${NC}"
    fi
done

echo -e "\n${GREEN}Done!${NC}"


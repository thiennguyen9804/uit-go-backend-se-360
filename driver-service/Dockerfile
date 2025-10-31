FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8081
EXPOSE 8386

USER root
RUN mkdir -p /var/lib/apt/lists/partial &&   apt-get update && apt-get install -y ca-certificates && update-ca-certificates

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY proto-contracts ./proto-contracts
COPY ["./driver-service/driver-service.csproj", "./"]
RUN dotnet restore "./driver-service.csproj"
COPY ./driver-service .
WORKDIR "/src/"
RUN dotnet publish "./driver-service.csproj" -c Release -o /app/publish /p:PublishTrimmed=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish ./
ENTRYPOINT ["dotnet", "driver-service.dll"]

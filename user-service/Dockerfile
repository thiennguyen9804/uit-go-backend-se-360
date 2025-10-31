FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080

USER root
RUN mkdir -p /var/lib/apt/lists/partial &&   apt-get update && apt-get install -y ca-certificates && update-ca-certificates

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY proto-contracts /src/proto-contracts
COPY ["./user-service/user-service.csproj", "./"]
RUN dotnet restore "user-service.csproj"
COPY ./user-service .

WORKDIR "/src/"
RUN dotnet build "./user-service.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./user-service.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "user-service.dll"]

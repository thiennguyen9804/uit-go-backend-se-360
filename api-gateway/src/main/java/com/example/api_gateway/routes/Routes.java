package com.example.api_gateway.routes;

import org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.web.servlet.function.RequestPredicates;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerResponse;
import static org.springframework.cloud.gateway.server.mvc.filter.FilterFunctions.setPath;
import static org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions.route;

import java.net.URI;

import org.springframework.cloud.gateway.server.mvc.filter.BeforeFilterFunctions;
import org.springframework.cloud.gateway.server.mvc.filter.CircuitBreakerFilterFunctions;

@Configuration
public class Routes {
  @Bean
  public RouterFunction<ServerResponse> userServiceRoute() {
    return GatewayRouterFunctions
        .route("user_service")
        .route(RequestPredicates.path("/api/users"), HandlerFunctions.http())
        .before(BeforeFilterFunctions.uri("http://localhost:8080"))
        .build();
  }

  // @Bean
  // this is archived, for right now, no need for swagger
  public RouterFunction<ServerResponse> productServiceSwaggerRoute() {
    return GatewayRouterFunctions.route("product_service_swagger")
        .route(RequestPredicates.path("/aggregate/product-service/v3/api-docs"),
            HandlerFunctions.http())
        .before(BeforeFilterFunctions.uri("http://localhost:8080"))
        .filter(CircuitBreakerFilterFunctions.circuitBreaker("productServiceSwaggerCircuitBreaker",
            URI.create("forward:/fallbackRoute")))
        .filter(setPath("/api-docs"))
        .build();
  }

  @Bean
  public RouterFunction<ServerResponse> driverServiceRoute() {
    return GatewayRouterFunctions
        .route("driver_service")
        .route(
            RequestPredicates.path("/api/drivers"),
            HandlerFunctions.http())
        .before(BeforeFilterFunctions.uri("http://localhost:8081"))
        // .filter(CircuitBreakerFilterFunctions.circuitBreaker("orderServiceCircuitBreaker",
        // URI.create("forward:/fallbackRoute")))
        .build();
  }

  @Bean
  public RouterFunction<ServerResponse> tripServiceRoute() {
    return GatewayRouterFunctions
        .route("trip_service")
        .route(RequestPredicates.path("/api/trips"), HandlerFunctions.http())
        .before(BeforeFilterFunctions.uri("http://localhost:8082"))
        .build();
  }

  @Bean
  // this is archived, for right now, no need for fallback route
  public RouterFunction<ServerResponse> fallbackRoute() {
    return route("fallbackRoute")
        .GET("/fallbackRoute",
            request -> ServerResponse.status(HttpStatus.SERVICE_UNAVAILABLE).body("Service Unavailable"))
        .build();
  }
}

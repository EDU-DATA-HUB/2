package com.vanhuy.api_gateway.component;

import com.vanhuy.api_gateway.dto.ValidTokenResponse;
import com.vanhuy.api_gateway.service.AuthService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.Arrays;
import java.util.List;

@Component
public class ConfigGlobalFilter implements GlobalFilter, Ordered {
    private static final Logger logger = LoggerFactory.getLogger(ConfigGlobalFilter.class);

    private final AuthService authService;
    private static final List<String> PUBLIC_ENDPOINTS = Arrays.asList(
            "/api/v1/auth/login",
            "/api/v1/auth/register",
            "/api/v1/auth/forgot",
            "/api/v1/auth/reset",
            "/aggregate/",
            "/swagger-ui/index.html",
            "/swagger-ui/",
            "/api-docs/",
            "/api/v1/restaurants",
            "/api/v1/menu-items"
    );

    public ConfigGlobalFilter(AuthService authService) {
        this.authService = authService;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();

        if (isPublicEndpoint(path)) {
            return chain.filter(exchange);
        }

        String token = extractToken(exchange);
        if (token == null) {
            return handleUnauthorized(exchange);
        }

        try {
            ValidTokenResponse validateToken = authService.validateToken(token);
            if (validateToken == null || !validateToken.isValid()) {
                logger.warn("Invalid token: {}", token);
                return handleUnauthorized(exchange);
            }
        } catch (RuntimeException e) {
            // Log the error
            logger.error("Error during token validation", e);
            return handleServerError(exchange, e);
        }
        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }

    private boolean isPublicEndpoint(String path) {
        return PUBLIC_ENDPOINTS.stream().anyMatch(path::startsWith);
    }

    private String extractToken(ServerWebExchange exchange) {
        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        return null;
    }

    private Mono<Void> handleUnauthorized(ServerWebExchange exchange) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }

    private Mono<Void> handleServerError(ServerWebExchange exchange, Throwable e) {
        logger.error("Server error during request processing", e);
        exchange.getResponse().setStatusCode(HttpStatus.INTERNAL_SERVER_ERROR);
        return exchange.getResponse().setComplete();
    }
}
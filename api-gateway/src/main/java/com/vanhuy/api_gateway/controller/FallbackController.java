package com.vanhuy.api_gateway.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FallbackController {
    @GetMapping("/fallback/restaurant")
    public ResponseEntity<String> restaurantFallback() {
        return ResponseEntity.ok("Restaurant Service is currently unavailable. Please try again later.");
    }

    @GetMapping("/fallback/order")
    public ResponseEntity<String> orderFallback() {
        return ResponseEntity.ok("Order Service is currently unavailable. Please try again later.");
    }

    @GetMapping("/fallback/user")
    public ResponseEntity<String> userFallback() {
        return ResponseEntity.ok("User Service is currently unavailable. Please try again later.");
    }
}

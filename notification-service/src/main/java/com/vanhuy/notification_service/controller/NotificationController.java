package com.vanhuy.notification_service.controller;

import com.vanhuy.notification_service.dto.ApiResponse;
import com.vanhuy.notification_service.dto.EmailRequest;
import com.vanhuy.notification_service.dto.EmailResetRequest;
import com.vanhuy.notification_service.dto.OrderResponse;
import com.vanhuy.notification_service.kafka.EmailProducerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/notifications")
@Slf4j
public class NotificationController {
    private final EmailProducerService emailProducerService;

    // send email notification when use register
    @PostMapping("/welcome-email")
    public String sendEmail(@RequestBody EmailRequest emailRequest) {
        emailProducerService.sendEmail(emailRequest);
        return "Email sent successfully";
    }

    @PostMapping("/order")
    public ResponseEntity<String> sendOrderNotification(@RequestBody OrderResponse orderResponse) {
        emailProducerService.sendOrderNotification(orderResponse);
        return ResponseEntity.ok("Order notification sent successfully");
    }

    @PostMapping("/reset-password-email")
    public ResponseEntity<ApiResponse> sendEmail(@RequestBody EmailResetRequest request) {
        try {
            emailProducerService.sendPasswordResetRequest(request.getToEmail() ,request.getTemplateData());
            return ResponseEntity.ok(new ApiResponse(true, "Email sent successfully"));
        } catch (Exception e) {
            log.error("Failed to send email", e);
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(new ApiResponse(false, e.getMessage()));
        }
    }
}

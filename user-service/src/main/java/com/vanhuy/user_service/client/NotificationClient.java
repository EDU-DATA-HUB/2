package com.vanhuy.user_service.client;

import com.vanhuy.user_service.dto.EmailRequest;
import com.vanhuy.user_service.dto.resetPassword.EmailResetRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {
    private final RestTemplate restTemplate;

    @Value("${notification.service.url}")
    private String notificationServiceUrl;

    @Value("${app.frontend.url}")
    private String frontendUrl;


    public void sendWelcomeEmail(EmailRequest emailRequest) {
        try {
            String url = notificationServiceUrl + "/welcome-email";
            restTemplate.postForEntity(url, emailRequest, String.class);
            log.info("Welcome email sent successfully to {}", emailRequest.getToEmail());
        } catch (Exception e) {
            // Do not fail registration when mail/Kafka is unavailable locally
            log.warn("Welcome email skipped for {}: {}", emailRequest.getToEmail(), e.getMessage());
        }
    }


    public void sendPasswordResetEmail(String email, String token) {
        try{
            String resetLink = buildResetPasswordLink(token);
            EmailResetRequest emailRequest = buildPasswordResetEmailRequest(email, resetLink);

            String url = notificationServiceUrl + "/reset-password-email";
            ResponseEntity<String> response = restTemplate.postForEntity(url, emailRequest, String.class);

            if (response.getStatusCode() == HttpStatus.OK) {
                log.info("Password reset email sent successfully to: {}", email);
            } else {
                log.error("Unexpected response when sending password reset email. Status: {}",
                        response.getStatusCode());
                throw new NotificationException("Failed to send password reset email");
            }

        }catch (RestClientException e){
            log.error("Failed to send password reset email to {}", email, e);
            throw new NotificationException("Failed to send password reset email");
        }
    }

    private EmailResetRequest buildPasswordResetEmailRequest(String email, String resetLink) {
        Map<String, String> templateData = new HashMap<>();
        templateData.put("resetLink", resetLink);
        templateData.put("expirationHours", "24");
        return EmailResetRequest.builder()
                .toEmail(email)
                .templateId("PASSWORD_RESET")
                .templateData(templateData)
                .build();
    }

    private String buildResetPasswordLink(String token) {
        return frontendUrl + "/reset-password?token=" + token;
    }

}


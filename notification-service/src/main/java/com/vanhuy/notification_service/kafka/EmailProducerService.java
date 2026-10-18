package com.vanhuy.notification_service.kafka;

import com.vanhuy.notification_service.dto.EmailRequest;
import com.vanhuy.notification_service.dto.EmailResetRequest;
import com.vanhuy.notification_service.dto.OrderResponse;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class EmailProducerService {//    service để gửi yêu cầu email vào Kafka topic
    private final static Logger logger = LoggerFactory.getLogger(EmailProducerService.class);
    private final KafkaTemplate<String, Object> kafkaTemplate;

    @Value("${kafka.email-register-topic}")
    private String REGISTER_TOPIC;

    @Value("${kafka.forgot-password-topic}")
    private String FORGOT_PASSWORD_TOPIC;

    @Value("${kafka.order-notification-topic}")
    private String ORDER_TOPIC ;

    public void sendEmail(EmailRequest emailRequest) {
        kafkaTemplate.send(REGISTER_TOPIC, emailRequest);
        logger.info("Sent email request to Kafka topic: {}", REGISTER_TOPIC);
    }

    public void sendPasswordResetRequest(String toEmail, Map<String, String> templateData) {
        EmailResetRequest message = new EmailResetRequest(toEmail, null, templateData);
        kafkaTemplate.send(FORGOT_PASSWORD_TOPIC, message);
        logger.info("Sent password reset request to Kafka topic: {}", FORGOT_PASSWORD_TOPIC);
    }

    public void sendOrderNotification(OrderResponse orderResponse) {
        kafkaTemplate.send(ORDER_TOPIC, orderResponse);
        logger.info("Sent order notification to Kafka topic: {}", REGISTER_TOPIC);
    }
}
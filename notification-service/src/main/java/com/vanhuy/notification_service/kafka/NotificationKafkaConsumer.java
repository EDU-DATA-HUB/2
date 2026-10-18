package com.vanhuy.notification_service.kafka;

import com.vanhuy.notification_service.dto.EmailRequest;
import com.vanhuy.notification_service.dto.EmailResetRequest;
import com.vanhuy.notification_service.dto.OrderResponse;
import com.vanhuy.notification_service.service.EmailService;
import lombok.RequiredArgsConstructor;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationKafkaConsumer {//    Kafka Consumer để lắng nghe và xử lý các yêu cầu email cũng như send notification qua websocket

    private final static Logger logger = LoggerFactory.getLogger(NotificationKafkaConsumer .class);
    private final EmailService emailService;

    @KafkaListener(topics =
            {"${kafka.email-register-topic}", "${kafka.forgot-password-topic}","${kafka.order-notification-topic}"} ,
            groupId = "${spring.kafka.consumer.group-id}")
    public void listen(ConsumerRecord<String, Object> record) {
        Object message = record.value();
        try {
            if (message instanceof EmailRequest) {
                EmailRequest emailRequest = (EmailRequest) message;
                emailService.sendEmail(emailRequest.getToEmail(), emailRequest.getUsername());
                logger.info("Standard email sent successfully to {}", emailRequest.getToEmail());
            } else if (message instanceof EmailResetRequest) {
                EmailResetRequest resetRequest = (EmailResetRequest) message;
                emailService.sendForgotPasswordEmail(resetRequest.getToEmail(), resetRequest.getTemplateData());
                logger.info("Forgot password email sent successfully to {}", resetRequest.getToEmail());
            } else if (message instanceof OrderResponse) {
                OrderResponse orderResponse = (OrderResponse) message;
                emailService.sendOrderSuccessEmail(orderResponse.getContactEmail(), orderResponse);
                logger.info("Order notification sent successfully to {}", orderResponse.getContactEmail());
            } else {
                logger.warn("Unknown message type received: {}", message.getClass().getSimpleName());
            }
        } catch (Exception e) {
            logger.error("Error processing Kafka message: {}", e.getMessage(), e);
        }
    }

}
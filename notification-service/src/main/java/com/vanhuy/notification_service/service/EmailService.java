package com.vanhuy.notification_service.service;

import com.vanhuy.notification_service.dto.OrderResponse;
import javax.mail.MessagingException;
import javax.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.thymeleaf.exceptions.TemplateInputException;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class EmailService {
    @Value("${spring.mail.username}")
    private String from;

    private final JavaMailSender javaMailSender;
    private final TemplateEngine templateEngine;

    public void sendEmail(String toEmail,  String username) {
        try{
            MimeMessage msg = javaMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(msg, true);

            helper.setFrom(from);
            helper.setTo(toEmail);
            helper.setSubject("Welcome to our website");

            // create context
            Context context = new Context();
            context.setVariable("username", username);

            // process template
            String html = templateEngine.process("welcome", context);

            helper.setText(html, true);

            javaMailSender.send(msg);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public void sendForgotPasswordEmail(String toEmail, Map<String, String> templateData) {
        try {
            MimeMessage msg = javaMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(msg, true);

            helper.setFrom(from);
            helper.setTo(toEmail);
            helper.setSubject("Reset your password");

            // create context
            Context context = new Context();
            context.setVariable("resetLink", templateData.get("resetLink"));
            context.setVariable("expirationHours", templateData.get("expirationHours"));

            // process template
            String html = templateEngine.process("forgot-password", context);

            helper.setText(html, true);

            javaMailSender.send(msg);
        } catch (TemplateInputException | MessagingException e) {
            System.err.println("Error while parsing template for forgot password email: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public void sendOrderSuccessEmail(String toEmail,  OrderResponse orderResponse) {
        try {
            MimeMessage msg = javaMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(msg, true);

            helper.setFrom(from);
            helper.setTo(toEmail);
            helper.setSubject("Order confirmation");

            // create context
            Context context = new Context();
            context.setVariable("recipientName", orderResponse.getRecipientName());
            context.setVariable("orderId", orderResponse.getOrderId());
            context.setVariable("orderDate", orderResponse.getOrderDate());
            context.setVariable("totalAmount", orderResponse.getTotalAmount());
            context.setVariable("shippingAddress", orderResponse.getShippingAddress());
            context.setVariable("items", orderResponse.getItems());

            // process template
            String html = templateEngine.process("order-confirmation", context);

            helper.setText(html, true);

            javaMailSender.send(msg);
        } catch (TemplateInputException | MessagingException e) {
            System.err.println("Error while parsing template for order email: " + e.getMessage());
            e.printStackTrace();
        }
    }


}

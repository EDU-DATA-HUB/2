package com.vanhuy.user_service.client;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
public class NotificationException extends RuntimeException {
    public NotificationException(String message) {
        super(message);
    }
}
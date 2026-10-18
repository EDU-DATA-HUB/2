package com.vanhuy.notification_service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmailResetRequest {
    private String toEmail;
    private String templateId;
    private Map<String, String> templateData;
}
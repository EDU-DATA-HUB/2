package com.vanhuy.user_service.dto.resetPassword;

import lombok.Builder;
import lombok.Data;

import java.util.Map;

@Data
@Builder
public class EmailResetRequest {
    private String toEmail;
    private String templateId;
    private Map<String, String> templateData;
}

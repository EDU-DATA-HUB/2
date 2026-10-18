package com.vanhuy.user_service.dto;

import lombok.*;

@NoArgsConstructor
@AllArgsConstructor
@Builder
@Getter
@Setter
public class ValidTokenResponse {
    private boolean valid;
}

package com.vanhuy.order_service.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserDTO {
    private Integer userId;
    private String username;
    private String email;
    private String address;
}

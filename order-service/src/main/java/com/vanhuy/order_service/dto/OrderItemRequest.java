package com.vanhuy.order_service.dto;

import lombok.Data;

@Data
public class OrderItemRequest {
    private Integer menuItemId;
    private Integer quantity;
}

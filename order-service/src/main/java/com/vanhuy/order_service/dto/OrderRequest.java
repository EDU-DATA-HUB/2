package com.vanhuy.order_service.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class OrderRequest {
    private Integer userId;
    private String recipientName;
    private String contactEmail;
    private String shippingAddress;
    private String contactPhone;
    private List<OrderItemRequest> items;
}

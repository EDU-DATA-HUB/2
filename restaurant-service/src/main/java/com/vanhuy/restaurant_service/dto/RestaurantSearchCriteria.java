package com.vanhuy.restaurant_service.dto;

import lombok.Data;

@Data
public class RestaurantSearchCriteria {
    private String name;
    private String address;
    private int page = 0;
    private int size = 10;
    private String sortBy = "name";
    private String sortDirection = "asc";

}

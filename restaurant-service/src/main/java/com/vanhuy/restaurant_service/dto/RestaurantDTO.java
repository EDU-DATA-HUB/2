package com.vanhuy.restaurant_service.dto;

public class RestaurantDTO {
    private Integer restaurantId;
    private String name;
    private String address;
    private String image;

    public RestaurantDTO() {
    }

    public RestaurantDTO(Integer restaurantId, String name, String address, String image) {
        this.restaurantId = restaurantId;
        this.name = name;
        this.address = address;
        this.image = image;
    }

    public Integer restaurantId() {
        return restaurantId;
    }

    public String name() {
        return name;
    }

    public String address() {
        return address;
    }

    public String image() {
        return image;
    }

    public Integer getRestaurantId() {
        return restaurantId;
    }

    public void setRestaurantId(Integer restaurantId) {
        this.restaurantId = restaurantId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }
}

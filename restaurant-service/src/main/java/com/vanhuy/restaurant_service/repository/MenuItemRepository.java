package com.vanhuy.restaurant_service.repository;

import com.vanhuy.restaurant_service.model.MenuItem;
import com.vanhuy.restaurant_service.model.Restaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;


public interface MenuItemRepository extends JpaRepository<MenuItem , Integer> {
    List<MenuItem> findByRestaurant(Restaurant restaurant);
}

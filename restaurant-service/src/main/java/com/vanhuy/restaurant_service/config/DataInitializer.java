package com.vanhuy.restaurant_service.config;

import com.vanhuy.restaurant_service.model.MenuItem;
import com.vanhuy.restaurant_service.model.Restaurant;
import com.vanhuy.restaurant_service.repository.MenuItemRepository;
import com.vanhuy.restaurant_service.repository.RestaurantRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Arrays;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final RestaurantRepository restaurantRepository;
    private final MenuItemRepository menuItemRepository;

    @Override
    public void run(String... args) {
        if (restaurantRepository.count() > 0) {
            return;
        }

        Restaurant coffeeHouse = restaurantRepository.save(Restaurant.builder()
                .name("O-Coffee House")
                .address("12 Nguyen Hue, District 1")
                .build());

        Restaurant pizzaPlace = restaurantRepository.save(Restaurant.builder()
                .name("Napoli Pizza")
                .address("88 Le Loi, District 1")
                .build());

        Restaurant burgerJoint = restaurantRepository.save(Restaurant.builder()
                .name("Burger Station")
                .address("5 Vo Van Tan, District 3")
                .build());

        menuItemRepository.saveAll(Arrays.asList(
                menu("Espresso", "2.50", 100, coffeeHouse),
                menu("Cappuccino", "3.50", 100, coffeeHouse),
                menu("Croissant", "2.00", 50, coffeeHouse),
                menu("Margherita", "8.99", 40, pizzaPlace),
                menu("Pepperoni", "10.99", 40, pizzaPlace),
                menu("Garlic Bread", "3.99", 60, pizzaPlace),
                menu("Classic Burger", "6.99", 80, burgerJoint),
                menu("Cheese Fries", "3.49", 80, burgerJoint),
                menu("Milkshake", "4.29", 70, burgerJoint)
        ));

        log.info("Seeded sample restaurants and menu items for local use");
    }

    private MenuItem menu(String name, String price, int stock, Restaurant restaurant) {
        return MenuItem.builder()
                .name(name)
                .price(new BigDecimal(price))
                .stock(stock)
                .restaurant(restaurant)
                .build();
    }
}

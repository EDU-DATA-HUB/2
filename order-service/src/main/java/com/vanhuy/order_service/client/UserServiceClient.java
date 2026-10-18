package com.vanhuy.order_service.client;

import com.vanhuy.order_service.dto.UserDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "user-service", url = "${clients.user-service.url:http://localhost:8081}")
public interface UserServiceClient {

    @GetMapping("/api/v1/users/{userId}")
    UserDTO getUserById(@PathVariable Integer userId);
}

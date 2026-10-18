package com.vanhuy.api_gateway.controller;

import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/gateway")
public class GatewayController {

    private final DiscoveryClient discoveryClient;

    public GatewayController(DiscoveryClient discoveryClient) {
        this.discoveryClient = discoveryClient;
    }

    // expose the services connected to the API Gateway
    @GetMapping("/services-connected")
    public Map<String, List<String>> getServices() {
        List<String> services = discoveryClient.getServices();
        Map<String, List<String>> serviceDetails = new HashMap<>();

        for (String service : services) {
            List<String> instances = discoveryClient.getInstances(service)
                    .stream()
                    .map(instance -> instance.getUri().toString())
                    .collect(Collectors.toList());
            serviceDetails.put(service, instances);
        }

        return serviceDetails;
    }
}
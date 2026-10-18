package com.vanhuy.order_service.service;

import com.vanhuy.order_service.client.NotificationClient;
import com.vanhuy.order_service.client.RestaurantClient;
import com.vanhuy.order_service.client.UserServiceClient;
import com.vanhuy.order_service.constant.Constants;
import com.vanhuy.order_service.dto.OrderItemResponse;
import com.vanhuy.order_service.dto.OrderRequest;
import com.vanhuy.order_service.dto.OrderResponse;
import com.vanhuy.order_service.dto.UserDTO;
import com.vanhuy.order_service.exception.ResourceNotFoundException;
import com.vanhuy.order_service.model.Order;
import com.vanhuy.order_service.model.OrderItem;
import com.vanhuy.order_service.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    Logger logger = LoggerFactory.getLogger(OrderService.class);

    private final UserServiceClient userServiceClient;
    private final OrderRepository orderRepository;
    private final RestaurantClient restaurantClient;
    private final NotificationClient notificationClient;

    // create order
    public OrderResponse createOrder(OrderRequest orderRequest) {
        Order order = new Order();
        order.setUserId(orderRequest.getUserId());
        order.setStatus(Order.OrderStatus.PENDING);
        order.setPaymentStatus(Order.PaymentStatus.PENDING);
        order.setOrderDate(LocalDateTime.now());
        order.setRecipientName(orderRequest.getRecipientName());
        order.setContactEmail(orderRequest.getContactEmail());
        order.setShippingAddress(orderRequest.getShippingAddress());
        order.setContactPhone(orderRequest.getContactPhone());

        List<OrderItem> orderItems = orderRequest.getItems().stream()
                .map(orderItemRequest -> {
                    OrderItem orderItem = new OrderItem();
                    orderItem.setOrder(order);
                    orderItem.setMenuItemId(orderItemRequest.getMenuItemId());
                    orderItem.setQuantity(orderItemRequest.getQuantity());
                    orderItem.setSubtotal(
                            calculateSubtotal(orderItemRequest.getMenuItemId(), orderItemRequest.getQuantity()));
                    return orderItem;
                })
                .collect(Collectors.toList());

        order.setOrderItems(orderItems);
        BigDecimal subtotal = orderItems.stream()
                .map(OrderItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // calculate tax
        BigDecimal tax = subtotal.multiply(Constants.TAX_RATE);

        order.setTotalAmount(subtotal.add(tax));

        Order savedOrder = orderRepository.save(order);
        logger.info("Order created: " + savedOrder);

        // send order notification
        OrderResponse orderResponse = orderToOrderResponse(savedOrder);
        sendOrderNotification(orderResponse);

        return orderResponse;
    }

    private BigDecimal calculateSubtotal(Integer menuItemId, Integer quantity) {
        BigDecimal price = restaurantClient.getPriceByMenuItemId(menuItemId);
        return price.multiply(BigDecimal.valueOf(quantity));
    }

    // get all orders
    public Page<OrderResponse> getAllOrders(Pageable pageable) {
        return orderRepository.findAll(pageable)
                .map(this::orderToOrderResponse);
    }

    public OrderResponse getOrderById(Integer orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
        return orderToOrderResponse(order);
    }


    private OrderResponse orderToOrderResponse(Order order) {
        OrderResponse response = new OrderResponse();
        response.setOrderId(order.getOrderId());
        response.setUserId(order.getUserId());
        response.setOrderDate(order.getOrderDate());
        response.setTotalAmount(order.getTotalAmount());
        response.setStatus(order.getStatus().name());
        response.setPaymentStatus(order.getPaymentStatus().name());
        response.setRecipientName(order.getRecipientName());
        response.setContactEmail(order.getContactEmail());
        response.setShippingAddress(order.getShippingAddress());
        response.setContactPhone(order.getContactPhone());

        List<OrderItemResponse> itemResponses = order.getOrderItems().stream()
                .map(item -> {
                    OrderItemResponse itemResponse = new OrderItemResponse();
                    itemResponse.setOrderItemId(item.getOrderItemId());
                    itemResponse.setMenuItemId(item.getMenuItemId());
                    itemResponse.setQuantity(item.getQuantity());
                    itemResponse.setSubtotal(item.getSubtotal());
                    return itemResponse;
                })
                .collect(Collectors.toList());

        response.setItems(itemResponses);
        return response;
    }

    private void sendOrderNotification(OrderResponse orderResponse) {
        CompletableFuture.runAsync(() -> {
            notificationClient.sendOrderNotification(orderResponse);
        }).exceptionally(ex -> {
            logger.error("Failed to send order notification for order: {}", orderResponse.getOrderId(), ex);
            return null;
        });
    }

    public UserDTO getOrderInfo(Integer userId) {
        UserDTO userDTO = userServiceClient.getUserById(userId);
        return  userDTO;
    }

}

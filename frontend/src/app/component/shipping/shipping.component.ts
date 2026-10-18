import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { OrderService } from '../../service/order.service';
import { OrderRequest } from '../../dto/order/order-request';
import { CartService } from '../../service/cart.service';
import { CartItem } from '../../dto/CartItem';
import { Observable, map, switchMap, take } from 'rxjs';
import { environment } from '../../../environments/enviroment';
import { UserService } from '../../service/user.service';

@Component({
  selector: 'app-shipping',
  templateUrl: './shipping.component.html',
  styleUrl: './shipping.component.css'
})
export class ShippingComponent implements OnInit {

  shippingForm!: FormGroup;
  cartItems$: Observable<CartItem[]> | undefined;
  total$: Observable<number> | undefined;
  baseUrl = environment.baseUrl;
  userId! : number ;
  constructor(
    private formBuilder: FormBuilder,
    private router: Router,
    private orderService: OrderService,
    private cartService: CartService,
    private UserService: UserService,
  ) { }

  ngOnInit(): void {
    this.getUserId();
    this.shippingForm = this.formBuilder.group({
      recipientName: ['', Validators.required],
      contactEmail: ['', Validators.required],
      shippingAddress: ['', Validators.required],
      contactPhone: ['', Validators.required]
    });
    this.cartItems$ = this.cartService.getCartItems();
    this.total$ = this.cartItems$.pipe(
      map(items => items.reduce((total, item) => total + item.menuItem.price * item.quantity, 0))
    );
  }

  onSubmit() {
    if (this.shippingForm.valid) {
      this.cartItems$?.pipe(
        take(1), // Only take the first emission from cartItems$
        map(items => items.map(cartItem => ({  // Convert CartIteam from local to OrderItem
          menuItemId: cartItem.menuItem.menuItemId,
          quantity: cartItem.quantity
        }))),
        switchMap(orderItems => {  // Switch to the orderService.createOrder Observable
          const orderRequest: OrderRequest = {
            userId: this.userId,
            ...this.shippingForm.value,
            items: orderItems
          };
          return this.orderService.createOrder(orderRequest); // This returns the Observable from the orderService
        })
      ).subscribe({
        next: (order) => {
          this.router.navigate(['/order-confirmation', order.orderId]);
          this.cartService.clearCart();
        },
        error: (err) => {
          console.error("Error creating order:", err); // Handle errors gracefully
        }
      });
    }
  }

  getUserId() {
    this.UserService.user$.subscribe(user => {
      this.userId = user?.userId!;
      console.log(this.userId);
    });
  }

}

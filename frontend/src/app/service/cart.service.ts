import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { CartItem } from '../dto/CartItem';

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private cartItemsSubject: BehaviorSubject<CartItem[]> = new BehaviorSubject<CartItem[]>([]);
  private cartItemCountSubject: BehaviorSubject<number> = new BehaviorSubject<number>(0);
  
  constructor() {
    this.loadCart();
  }

  getCartItems(): Observable<CartItem[]> {
    return this.cartItemsSubject.asObservable();
  }

  getCartItemCount(): Observable<number> {
    return this.cartItemCountSubject.asObservable();
  }
  addToCart(item: CartItem): void {
    const currentCart = this.cartItemsSubject.value;
    const existingItemIndex = currentCart.findIndex(i => i.menuItem.menuItemId === item.menuItem.menuItemId);
    
    if (existingItemIndex !== -1) {
      currentCart[existingItemIndex].quantity += item.quantity;
    } else {
      currentCart.push(item);
    }
    
    this.updateCart(currentCart);
  }

  removeFromCart(itemId: number): void {
    const updatedCart = this.cartItemsSubject.value.filter(item => item.menuItem.menuItemId !== itemId);
    this.updateCart(updatedCart);
  }

  updateItemQuantity(itemId: number, quantity: number): void {
    const currentCart = this.cartItemsSubject.value;
    const itemIndex = currentCart.findIndex(item => item.menuItem.menuItemId === itemId);
    
    if (itemIndex !== -1) {
      if (quantity <= 0) {
        currentCart.splice(itemIndex, 1);
      } else {
        currentCart[itemIndex].quantity = quantity;
      }
      this.updateCart(currentCart);
    }
  }

  clearCart(): void {
    this.updateCart([]);
  }

  private loadCart(): void {
    const savedCart = localStorage.getItem('cart');
    const cartItems = savedCart ? JSON.parse(savedCart) : [];
    this.updateCart(cartItems);
  }

  private updateCart(cart: CartItem[]): void {
    this.cartItemsSubject.next(cart);
    this.cartItemCountSubject.next(this.calculateTotalItems(cart));
    localStorage.setItem('cart', JSON.stringify(cart));
  }

  private calculateTotalItems(cart: CartItem[]): number {
    return cart.reduce((total, item) => total + item.quantity, 0);
  }
}
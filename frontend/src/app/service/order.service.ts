import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Order } from '../dto/order/order-response';
import { OrderRequest } from '../dto/order/order-request';
import { environment } from '../../environments/enviroment';

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  
  // private orderUrl = 'http://localhost:8083/api/v1/orders';
  private orderUrl = `${environment.baseUrl}/orders`;
  constructor(
    private http : HttpClient
  ) { }

  createOrder(orderRequest: OrderRequest): Observable<Order> {
    return this.http.post<Order>(this.orderUrl, orderRequest);
  }

  getOrder(orderId: number):Observable<Order> {
    return this.http.get<Order>(`${this.orderUrl}/${orderId}`);
  }
}

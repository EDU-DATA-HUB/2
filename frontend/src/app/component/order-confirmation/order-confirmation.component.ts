import { Component } from '@angular/core';
import { Observable, switchMap } from 'rxjs';
import { Order } from '../../dto/order/order-response';
import { ActivatedRoute } from '@angular/router';
import { OrderService } from '../../service/order.service';

@Component({
  selector: 'app-order-confirmation',
  templateUrl: './order-confirmation.component.html',
  styleUrl: './order-confirmation.component.css'
})
export class OrderConfirmationComponent {
  order$ : Observable<Order> | undefined;

  constructor(
    private orderService : OrderService,
    private route : ActivatedRoute
  ) { 
  }
  ngOnInit(): void {
    this.order$ = this.route.paramMap.pipe(
      switchMap(params => {
        const id = Number(params.get('orderId'));
        return this.orderService.getOrder(id);
      })
    );
  }
}

import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Restaurant } from '../dto/Restaurant';
import { Page } from '../dto/Page';
import { MenuItem } from '../dto/MenuItem';
import { environment } from '../../environments/enviroment';

@Injectable({
  providedIn: 'root'
})
export class RestaurantService {
  private restaurantUrl = `${environment.baseUrl}/restaurants`;
  private menuUrl = `${environment.baseUrl}/menu-items`;

  // private restaurantUrl = 'http://localhost:8082/api/v1/restaurants';
  // private menuUrl = 'http://localhost:8082/api/v1/menu-items';

  constructor(private http: HttpClient) { }

  getAllRestaurants(page: number, size: number , keyword? : string): Observable<Page<Restaurant>> {
    let param = new HttpParams().set('page', page.toString()).set('size', size.toString());
    if (keyword) {
      param = param.set('keyword', keyword);
    }
    return this.http.get<Page<Restaurant>>(this.restaurantUrl, { params: param });
  }

  getMenuItemsByRestaurantId(restaurantId: number): Observable<MenuItem[]> {
    return this.http.get<MenuItem[]>(`${this.menuUrl}/restaurant/${restaurantId}`);
  }
}

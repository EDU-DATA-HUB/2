import { Component, OnInit } from '@angular/core';
import { Observable, Subscription } from 'rxjs';
import { CartService } from './service/cart.service';
import { AuthService } from './service/auth.service';
import { UserDTO } from './dto/auth/UserDTO';
import { UserService } from './service/user.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {
  title = 'Restaurant List';
  
  cartItemCount$: Observable<number> | undefined;
  isLoggedIn: boolean = false;
  currentUser: string | null = null;
  isDropdownOpen: boolean = false;

  userInfo : UserDTO | null = null;
  
  constructor(
    private cartService: CartService,
    private authService: AuthService,
    private userService: UserService,
    private router : Router
  ) {
    
  }
  ngOnInit(): void {
    this.cartItemCount$ = this.cartService.getCartItemCount();

    // Subscribe vào trạng thái đăng nhập
    this.authService.isLoggedIn$.subscribe(status => {
      this.isLoggedIn = status;
      if (status) {
        const username = this.authService.getUsernameFromToken();
        if (username) {
          this.userService.getUserByUsername(username).subscribe(user => {
            this.userInfo = user; 
            this.userService.setUserInfo(user); 
          });
        }
      }

    });

     // Subscribe vào tên người dùng
     this.authService.currentUser$.subscribe(username => {
      this.currentUser = username;
    });

    
  }

  toggleDropdown() {
    this.isDropdownOpen = !this.isDropdownOpen;
  }

  logout() {
    this.authService.logout();
    this.isDropdownOpen = false;
    // redirect to home page
    this.router.navigate(['/']);
  }
  
}

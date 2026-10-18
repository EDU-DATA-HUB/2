import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';
import { RestaurantDetailComponent } from './component/restaurant-detail/restaurant-detail.component';
import { ListRestaurantComponent } from './component/list-restaurant/list-restaurant.component';
import { CartComponent } from './component/cart/cart.component';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { OrderConfirmationComponent } from './component/order-confirmation/order-confirmation.component';
import { ShippingComponent } from './component/shipping/shipping.component';
import { LoginComponent } from './component/login/login.component';
import { AuthInterceptor } from './interceptor/auth-interceptor.interceptor';
import { RegisterComponent } from './component/register/register.component';
import { ProfileComponent } from './component/profile/profile.component';
import { ForgotPasswordComponent } from './component/forgot-password/forgot-password.component';
import { ResetPasswordComponent } from './component/reset-password/reset-password.component';
import { UnauthorizedComponent } from './component/unauthorized/unauthorized.component';
import { DashboardComponent } from './component/admin/dashboard/dashboard.component';
import { UserManagementComponent } from './component/admin/user-management/user-management.component';
import { RestaurantManagementComponent } from './component/admin/restaurant-management/restaurant-management.component';
import { OrderManagementComponent } from './component/admin/order-management/order-management.component';
import { UserFormDialogComponent } from './component/admin/user-form-dialog/user-form-dialog.component';


@NgModule({
  declarations: [
    AppComponent,
    RestaurantDetailComponent,
    ListRestaurantComponent,
    CartComponent,
    OrderConfirmationComponent,
    ShippingComponent,
    LoginComponent,
    RegisterComponent,
    ProfileComponent,
    ForgotPasswordComponent,
    ResetPasswordComponent,
    UnauthorizedComponent,
    DashboardComponent,
    UserManagementComponent,
    RestaurantManagementComponent,
    OrderManagementComponent,
    UserFormDialogComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule
  ],
  providers: [
    { provide : HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
  ],
  bootstrap: [AppComponent]
})
export class AppModule {
  
 }

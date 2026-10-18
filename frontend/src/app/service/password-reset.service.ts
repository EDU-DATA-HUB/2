import { Injectable } from '@angular/core';
import { environment } from '../../environments/enviroment';
import { HttpClient } from '@angular/common/http';
import { ForgotPasswordRequest } from '../dto/password-reset/ForgotPasswordRequest';
import { Observable } from 'rxjs';
import { PasswordResetResponse } from '../dto/password-reset/PasswordResetResponse';
import { ResetPasswordRequest } from '../dto/password-reset/ResetPasswordRequest';

@Injectable({
  providedIn: 'root'
})
export class PasswordResetService {
  private resetPasswordUrl = environment.baseUrl + '/auth';
  // private resetPasswordUrl = "http://localhost:8081/api/v1/auth";
  constructor(
    private http: HttpClient
  ) { }

  forgotPassword(request: ForgotPasswordRequest) : Observable<PasswordResetResponse> {
    return this.http.post<PasswordResetResponse>(`${this.resetPasswordUrl}/forgot`, request);
  }

  resetPassword(request: ResetPasswordRequest) : Observable<PasswordResetResponse> {
    return this.http.post<PasswordResetResponse>(`${this.resetPasswordUrl}/reset`, request);
  }
}

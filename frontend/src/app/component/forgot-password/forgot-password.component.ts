import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { PasswordResetService } from '../../service/password-reset.service';


@Component({
  selector: 'app-forgot-password',
  templateUrl: './forgot-password.component.html',
  styleUrl: './forgot-password.component.css'
})
export class ForgotPasswordComponent {
  forgotPasswordForm!: FormGroup;
  loading = false;
  error = '';
  success = false;
  successMessage = '';

  constructor(
    private formBuilder: FormBuilder,
    private passwordResetService: PasswordResetService,
  ){
    
    this.initForm();
  }
  private initForm(): void {
    this.forgotPasswordForm = this.formBuilder.group({
      email: ['', [Validators.required, Validators.email]]
    });
  }
  isFieldInvalid(fieldName: string): boolean {
    const field = this.forgotPasswordForm.get(fieldName);
    return field ? field.invalid && (field.dirty || field.touched) : false;
  }

  getFieldError(fieldName: string): string {
    const field = this.forgotPasswordForm.get(fieldName);
    if (field?.errors) {
      if (field.errors['required']) {
        return 'This field is required';
      }
      if (field.errors['email']) {
        return 'Please enter a valid email address';
      }
    }
    return '';
  }

  onSubmit() {

    if(this.forgotPasswordForm.invalid) {
      return;
    }

    this.loading = true;
    this.error = '';
    this.success = false;
    this.passwordResetService.forgotPassword({email: this.forgotPasswordForm.get('email')?.value})
    .subscribe(
      {
        next: (response) => {
          if (response.success) {
            this.success = true;
            this.successMessage = response.message;
            this.forgotPasswordForm.reset();
          } else {
            this.error = response.message;
          }
        },
        error: (error) => {
          this.error = 'An error occurred. Please try again later.';
          // this.loading = true;
        },
        complete: () => {
          this.loading = false;
        }
      }
    )
  }
}

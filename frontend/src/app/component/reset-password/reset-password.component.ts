import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { PasswordResetService } from '../../service/password-reset.service';

@Component({
  selector: 'app-reset-password',
  templateUrl: './reset-password.component.html',
  styleUrl: './reset-password.component.css'
})
export class ResetPasswordComponent {
  resetPasswordForm!: FormGroup;
  loading = false;
  error = '';
  success = false;
  successMessage = '';
  token: string = '';

  constructor(
    private formBuilder: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private PasswordResetService: PasswordResetService,
  ) {
    this.initForm();
  }

  ngOnInit(): void {
    this.token = this.route.snapshot.queryParams['token'];
    if (!this.token) {
      this.router.navigate(['/forgot-password']);
    }

  }

  private initForm(): void {
    this.resetPasswordForm = this.formBuilder.group({
      newPassword: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', [Validators.required]]
    }, { validators: this.passwordMatchValidator });
  }

  isFieldInvalid(fieldName: string): boolean {
    const field = this.resetPasswordForm.get(fieldName);
    return !!(field && field.invalid && (field.dirty || field.touched));
  }

  getFieldError(fieldName: string): string {
    const field = this.resetPasswordForm.get(fieldName);
    if (field?.errors) {
      if (field.errors['required']) {
        return 'This field is required';
      }
      if (field.errors['minlength']) {
        return 'Password must be at least 6 characters';
      }
    }

    // Check for form-level password match error
    if (fieldName === 'confirmPassword' && this.resetPasswordForm.errors?.['passwordMismatch']) {
      return 'Passwords do not match';
    }

    return '';
  }

  passwordMatchValidator(group: FormGroup) {
    const newPassword = group.get('newPassword')?.value;
    const confirmPassword = group.get('confirmPassword')?.value;
    return newPassword === confirmPassword ? null : { passwordMismatch: true };
  }

  onSubmit(): void {
    if (this.resetPasswordForm.invalid) {
      Object.keys(this.resetPasswordForm.controls).forEach(key => {
        const control = this.resetPasswordForm.get(key);
        if (control) {
          control.markAsTouched();
        }
      });
      return;
    }

    this.loading = true;
    this.error = '';
    this.success = false;

    const newPassword = this.resetPasswordForm.get('newPassword')?.value;

    this.PasswordResetService.resetPassword({ token: this.token, newPassword: newPassword })
      .subscribe(
        {
          next: (response) => {
            if (response.success) {
              this.success = true;
              this.successMessage = response.message;
              setTimeout(() => {
                this.router.navigate(['/login']);
              }, 3000);
            } else {
              this.error = response.message;
            }
          },
          error: (error) => {
            this.error = 'An error occurred. Please try again later.';
        
          },
          complete: () => {
            this.loading = false;
          }
          
        }
      )

  }

}

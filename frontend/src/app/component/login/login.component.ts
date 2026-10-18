import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { AuthService } from '../../service/auth.service';
import { ActivatedRoute, Router  } from '@angular/router';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  public loginForm: FormGroup;
  username: string = '';
  password: string = '';
  error: string = '';
  returnUrl :string = '/';

  constructor(
    private formBuilder: FormBuilder,
    private authService: AuthService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.loginForm = this.formBuilder.group({
      username: ['', [Validators.required]],
      password: ['', [Validators.required]]
    });
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/';
  }

  onSubmit() {
    this.error = '';
    // Mark all fields as touched to trigger validation messages
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    const { username, password } = this.loginForm.value;

    this.authService.login(username, password).subscribe({
      next :() => {
        this.router.navigateByUrl(this.returnUrl);
      },
      error: (error) => {
        // Handle login error
        this.error = error.message;
        console.error('Login failed', error);
      }}
    );
  }

  // Method to check if any field is invalid and touched
  isFieldInvalid(field: string): boolean {
    const control = this.loginForm.get(field);
    return control ? control.invalid && control.touched : false;
  }

  // Optionally, a method to get error message for specific validation rules
  getFieldError(field: string): string | null {
    const control = this.loginForm.get(field);
    if (control?.hasError('required')) {
      return `${field} is required`;
    }
    return null;
  }

}

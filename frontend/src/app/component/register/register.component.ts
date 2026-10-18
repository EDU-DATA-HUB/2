import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { AuthService } from '../../service/auth.service';


@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css']
})
export class RegisterComponent implements OnInit {
  registerForm: FormGroup;
  username: string = '';
  email: string = '';
  password: string = '';
  confirmPassword: string = '';
  error: string | null = null;
  success: string | null = null;

  constructor(
    private fb: FormBuilder, 
    private authService: AuthService) 
    {
    this.registerForm = this.fb.group({
      username: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', Validators.required]
    }, { validator: this.passwordMatchValidator });
  }

  ngOnInit(): void {}

  passwordMatchValidator(form: FormGroup) {
    return form.get('confirmPassword')?.value === form.get('password')?.value ? null : { mismatch: true };
  }

  isFieldInvalid(field: string): boolean | undefined {
    return this.registerForm.get(field)?.invalid && (this.registerForm.get(field)?.touched || this.registerForm.get(field)?.dirty);
  }

  getFieldError(field: string): string {
    if (this.registerForm.get(field)?.hasError('required')) {
      return 'This field is required';
    }
    if (this.registerForm.get(field)?.hasError('email')) {
      return 'Invalid email format';
    }
    if (this.registerForm.get(field)?.hasError('minlength')) {
      return 'Password must be at least 6 characters long';
    }
    if (this.registerForm.hasError('mismatch')) {
      return 'Passwords do not match';
    }
    return '';
  }

  onSubmit(): void {
    this.error = '';
    this.success = '';
    if (this.registerForm.valid) {
      const { username, email, password } = this.registerForm.value;
      this.authService.register(username, email, password).subscribe(
       {
        next: () => {
          // Handle successful registration
          this.success = 'Registration successful';
        },
        error: (error) => {
          // Handle registration error
          this.error = error.message;
          // console.log('Registration failed', error);
          
        }
       }
      );
    }
  }
}

import { Component, EventEmitter, Input, Output } from '@angular/core';
import { UserDTO } from '../../../dto/auth/UserDTO';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { UserService } from '../../../service/user.service';

@Component({
  selector: 'app-user-form-dialog',
  templateUrl: './user-form-dialog.component.html',
  styleUrl: './user-form-dialog.component.css'
})
export class UserFormDialogComponent {
  @Input() user?: UserDTO;
  @Output() close = new EventEmitter<void>();
  @Output() userSaved = new EventEmitter<void>();

  form!: FormGroup;
  isEditMode!: boolean;
  errorMessage = '';
  isLoading = false;
  availableRoles = ['ROLE_USER', 'ROLE_ADMIN'];

  constructor(
    private fb: FormBuilder,
    private userService: UserService
  ) {
    this.initForm();
  }

  ngOnInit(): void {
    this.isEditMode = !!this.user?.userId;
    this.initForm();
  }

  private initForm(): void {
    this.form = this.fb.group({
      userId: [this.user?.userId],
      username: [this.user?.username, [Validators.required, Validators.minLength(3)]],
      email: [this.user?.email, [Validators.required, Validators.email]],
      password: [null, this.isEditMode ? [] : [Validators.required, Validators.minLength(6)]],
      address: [this.user?.address],
      roles: [this.user?.roles || ['ROLE_USER']],
      isActive: [this.user?.active !== undefined ? this.user.active : true]
    });
  }

  onSubmit(): void {
    if (this.form.valid) {
      this.isLoading = true;
      const userData = { ...this.form.value };
      
      if (this.isEditMode && !userData.password) {
        delete userData.password;
      }

      const operation = this.isEditMode ?
        this.userService.updateUser(userData.userId, userData) :
        this.userService.createUser(userData);

      operation.subscribe({
        next: () => {
          this.userSaved.emit();
        },
        error: (error) => {
          this.errorMessage = error.error.message;
          this.isLoading = false;
        }
      });
    }
  }

  toggleRole(role: string): void {
    const roles = this.form.get('roles')?.value as string[] || [];
    const index = roles.indexOf(role);
    
    if (index === -1) {
      roles.push(role);
    } else {
      roles.splice(index, 1);
    }
    
    this.form.patchValue({ roles });
  }
}

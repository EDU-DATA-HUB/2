import { Component, OnInit } from '@angular/core';
import { UserDTO } from '../../dto/auth/UserDTO';
import { UserService } from '../../service/user.service';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.css'
})
export class ProfileComponent implements OnInit {

  // user : UserDTO | null = null;
  profileForm: FormGroup;
  selectedFile: File | undefined = undefined;
  profileImageUrl: string = '';
  errorMessages: string = '';
  successMessage: string = '';
  

  constructor(private fb: FormBuilder,
    private userService: UserService) {
    this.profileForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(50)]],
      email: ['', [Validators.required, Validators.email]],
      address: ['', [Validators.maxLength(255)]],
    });
  }

  ngOnInit(): void {
    this.userService.getProfile().subscribe((profile) => {
      this.profileForm.patchValue({
        username: profile.username,
        email: profile.email,
        address: profile.address,
      });
      this.profileImageUrl = profile.profileImageUrl;
    },
    (error) => {
      console.error('Failed to fetch profile', error);
      this.errorMessages = 'Failed to load profile data';
    },
  );
  }

  onFileChange(event: any) {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
    }
  }
   // Submit form
   onSubmit(): void {
    if (this.profileForm.valid) {
      const profileData = this.profileForm.value;
      this.userService.updateProfile(profileData, this.selectedFile).subscribe(
        (response) => {
          console.log('Profile updated successfully', response);
          this.successMessage = 'Profile updated successfully';
          this.profileImageUrl = response.profileImageUrl;
        },
        (error) => {
          console.error('Failed to update profile', error);
          // Handle error
          this.errorMessages = error.msaage;
        }
      );
    }
  }

}

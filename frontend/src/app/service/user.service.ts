import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpHeaders, HttpParams } from '@angular/common/http';
import { BehaviorSubject, catchError, Observable, tap, throwError } from 'rxjs';
import { UserCreateDTO, UserDTO, UserUpdateDTO } from '../dto/auth/UserDTO';
import { ProfileResponse } from '../dto/user/ProfileResponse';
import { ProfileUpdateDTO } from '../dto/user/ProfileUpdateDTO';
import { AuthEventService } from './auth-event.service';
import { environment } from '../../environments/enviroment';
import { Page } from '../dto/Page';

@Injectable({
  providedIn: 'root'
})
export class UserService {

  private userUrl = environment.baseUrl + '/users';
  // private userUrl = "http://localhost:8081/api/v1/users";

  private userSubject = new BehaviorSubject<UserDTO | null>(null);
  user$ = this.userSubject.asObservable();

  constructor(
    private http: HttpClient,
    private authEventService: AuthEventService,
  ) { }

  getUserByUsername(username: string): Observable<UserDTO> {
    return this.http.get<UserDTO>(`${this.userUrl}/username/${username}`).pipe(
      tap(user => this.setUserInfo(user)),
      catchError(this.handleError)
    );
  }

  updateProfile(profile: ProfileUpdateDTO, image?: File): Observable<ProfileResponse> {
    const formData = new FormData();

    // Append the profile data as JSON
    formData.append('profile', new Blob([JSON.stringify(profile)], { type: 'application/json' }));

    // If an image is provided, append it
    if (image) {
      formData.append('image', image);
    }

    return this.http.put<ProfileResponse>(`${this.userUrl}/profile`, formData, {
      headers: new HttpHeaders({
        'Accept': 'application/json',
      }),
    }).pipe(
      tap((profileResponse: ProfileResponse) => {
        const currentUser = this.userSubject.getValue(); // Get the current user info
        debugger;
        if (currentUser) {
          // Update the userSubject with new profile details
          const updatedUser: UserDTO = {
            ...currentUser,
            username: profileResponse.username,
            email: profileResponse.email,
            address: profileResponse.address,
            profileImageUrl: profileResponse.profileImageUrl, // Add the profile image URL
          };
          this.setUserInfo(updatedUser); // Update BehaviorSubject with new user info

          if (profileResponse.newJwtToken) {
            // If a new JWT token is provided, update the local storage
            this.authEventService.emitTokenUpdate(profileResponse.newJwtToken);
          }
        }
      }),
      catchError(this.handleError)
    );
  }

  getProfile(): Observable<ProfileResponse> {
    return this.http.get<ProfileResponse>(`${this.userUrl}/profile`).pipe(
      tap((profileResponse: ProfileResponse) => {
        const currentUser = this.userSubject.getValue();
        if (currentUser) {
          const updatedUser: UserDTO = {
            ...currentUser,
            username: profileResponse.username,
            email: profileResponse.email,
            address: profileResponse.address,
            profileImageUrl: profileResponse.profileImageUrl, // Include profile image URL
          };
          this.setUserInfo(updatedUser);
        }
        // Handle JWT token update if provided
        if (profileResponse.newJwtToken) {
          this.authEventService.emitTokenUpdate(profileResponse.newJwtToken);
        }
      })
    );
  }

  setUserInfo(user: UserDTO) {
    this.userSubject.next(user);
  }

  getUserInfo(): UserDTO | null {
    return this.userSubject.getValue();
  }

  clearUserInfo() {
    this.userSubject.next(null);
  }

  private handleError(error: HttpErrorResponse): Observable<never> {
    let errorMessage = 'An error occurred';
    if (error.error instanceof ErrorEvent) {
      errorMessage = error.error.message;
    } else {
      errorMessage = `Error Code: ${error.status}\nMessage: ${error.message}`;
    }
    console.error(errorMessage);
    return throwError(() => new Error(errorMessage));
  }

  getAllUsers(page: number, size: number): Observable<Page<UserDTO>> {
    return this.http.get<Page<UserDTO>>(`${this.userUrl}?page=${page}&size=${size}`);
  }

  getUserById(userId: number): Observable<UserDTO> {
    return this.http.get<UserDTO>(`${this.userUrl}/${userId}`);
  }

  createUser(user: UserCreateDTO): Observable<UserDTO> {
    return this.http.post<UserDTO>(`${this.userUrl}`, user);
  }

  updateUser(id: number, user: UserUpdateDTO): Observable<UserDTO> {
    return this.http.put<UserDTO>(`${this.userUrl}/${id}`, user);
  }

  deactivateUser(id: number): Observable<void> {
    return this.http.post<void>(`${this.userUrl}/${id}/deactivate`, {});
  }

  reactivateUser(id: number): Observable<UserDTO> {
    return this.http.post<UserDTO>(`${this.userUrl}/${id}/reactivate`, {});
  }

  getUsers(includeInactive: boolean = false, page: number , size :number): Observable<Page<UserDTO>> {
    const params = new HttpParams()
    .set('includeInactive', includeInactive.toString())
      .set('page', page.toString())
      .set('size', size.toString());
    return this.http.get<Page<UserDTO>>(this.userUrl, { params });
  }
}

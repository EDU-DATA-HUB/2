export interface ProfileResponse {
    username: string;
    email: string;
    address: string;
    profileImageUrl: string;
    newJwtToken?: string;
  }
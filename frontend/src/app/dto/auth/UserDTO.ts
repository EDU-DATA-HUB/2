export interface UserDTO {
    userId: number;
    username : string;
    email: string;
    address?: string;
    profileImageUrl?: string;
    roles: string[];
    active: boolean;
}

export interface UserCreateDTO extends Omit<UserDTO, 'userId'> {
    password: string;
 }

 export interface UserUpdateDTO extends Partial<UserCreateDTO> {
    
 }
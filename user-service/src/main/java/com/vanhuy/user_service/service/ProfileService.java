package com.vanhuy.user_service.service;

import com.vanhuy.user_service.component.JwtUtil;
import com.vanhuy.user_service.dto.ProfileResponse;
import com.vanhuy.user_service.dto.ProfileUpdateDTO;
import com.vanhuy.user_service.exception.UserNotFoundException;
import com.vanhuy.user_service.model.User;
import com.vanhuy.user_service.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ProfileService {
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;
    private final JwtUtil jwtUtil;

    @Value("${app.base-url}")
    private String baseUrl;

    public ProfileResponse getProfile(Integer userId) {
        return userRepository.findById(userId)
                .map(this::buildProfileResponse)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
    }

    private ProfileResponse buildProfileResponse(User user) {
        String imageUrl = Optional.ofNullable(user.getProfileImageName())
                .map(fileName -> baseUrl + "/api/v1/users/profile/image/" + fileName)
                .orElse(null);

        return ProfileResponse.builder()
                .username(user.getUsername())
                .email(user.getEmail())
                .address(user.getAddress())
                .profileImageUrl(imageUrl)
                .build();
    }

    public ProfileResponse updateProfile(Integer userId, ProfileUpdateDTO profileDTO,
                                         MultipartFile profileImage) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        boolean usernameChanged = !user.getUsername().equals(profileDTO.getUsername());

        // Validate unique constraints
        validateProfileUpdate(user, profileDTO, usernameChanged);

        user.setUsername(profileDTO.getUsername());
        user.setEmail(profileDTO.getEmail());
        user.setAddress(profileDTO.getAddress());

        // Handle profile image update
        handleProfileImageUpdate(user, profileImage);

        User savedUser = userRepository.save(user);

        // Build and return response
        return buildProfileResponseWithToken(savedUser, usernameChanged);
    }

    private void handleProfileImageUpdate(User user, MultipartFile profileImage) {
        if (profileImage != null && !profileImage.isEmpty()) {
            // Delete existing profile image if exists
            Optional.ofNullable(user.getProfileImageName())
                    .ifPresent(fileStorageService::deleteFile);

            // Store new profile image
            String fileName = fileStorageService.storeFile(profileImage);
            user.setProfileImageName(fileName);
        }
    }

    /**
     * Builds profile response with new JWT token if username changed.
     */
    private ProfileResponse buildProfileResponseWithToken(User user, boolean usernameChanged) {
        String imageUrl = Optional.ofNullable(user.getProfileImageName())
                .map(fileName -> baseUrl + "/api/v1/users/profile/image/" + fileName)
                .orElse(null);

        return ProfileResponse.builder()
                .username(user.getUsername())
                .email(user.getEmail())
                .address(user.getAddress())
                .profileImageUrl(imageUrl)
                .newJwtToken(usernameChanged ? jwtUtil.generateToken(user) : null)
                .build();
    }

    private void validateProfileUpdate(User user, ProfileUpdateDTO profileDTO, boolean usernameChanged) {
        if (usernameChanged && userRepository.existsByUsername(profileDTO.getUsername())) {
            throw new IllegalArgumentException("Username already taken");
        }

        if (!user.getEmail().equals(profileDTO.getEmail()) &&
                userRepository.existsByEmail(profileDTO.getEmail())) {
            throw new IllegalArgumentException("Email already taken");
        }
    }
}

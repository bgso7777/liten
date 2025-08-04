package com.liten.api.dto;

import com.liten.api.model.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

public class AuthResponse {

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class Login {
        private String accessToken;
        private String refreshToken;
        private String tokenType = "Bearer";
        private Long expiresIn;
        private UserInfo user;
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class Register {
        private String accessToken;
        private String refreshToken;
        private String tokenType = "Bearer";
        private Long expiresIn;
        private UserInfo user;
        private String message = "회원가입이 완료되었습니다";
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class RefreshToken {
        private String accessToken;
        private String refreshToken;
        private String tokenType = "Bearer";
        private Long expiresIn;
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class UserInfo {
        private Long userId;
        private String email;
        private String nickname;
        private String profileImageUrl;
        private String appUniqueId;
        private User.AuthProvider provider;
        private User.SubscriptionType subscriptionType;
        private LocalDateTime subscriptionEndDate;
        private String languageCode;
        private String theme;
        private LocalDateTime lastLoginAt;
        private LocalDateTime createdAt;

        public static UserInfo from(User user) {
            return UserInfo.builder()
                    .userId(user.getUserId())
                    .email(user.getEmail())
                    .nickname(user.getNickname())
                    .profileImageUrl(user.getProfileImageUrl())
                    .appUniqueId(user.getAppUniqueId())
                    .provider(user.getProvider())
                    .subscriptionType(user.getSubscriptionType())
                    .subscriptionEndDate(user.getSubscriptionEndDate())
                    .languageCode(user.getLanguageCode())
                    .theme(user.getTheme())
                    .lastLoginAt(user.getLastLoginAt())
                    .createdAt(user.getCreatedAt())
                    .build();
        }
    }
}
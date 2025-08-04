package com.liten.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

public class AuthRequest {

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class Login {
        @NotBlank(message = "이메일은 필수입니다")
        @Email(message = "올바른 이메일 형식이 아닙니다")
        private String email;

        @NotBlank(message = "비밀번호는 필수입니다")
        private String password;

        private String deviceInfo;
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class Register {
        @NotBlank(message = "이메일은 필수입니다")
        @Email(message = "올바른 이메일 형식이 아닙니다")
        private String email;

        @NotBlank(message = "비밀번호는 필수입니다")
        @Size(min = 8, message = "비밀번호는 최소 8자 이상이어야 합니다")
        private String password;

        @Size(max = 50, message = "닉네임은 50자를 초과할 수 없습니다")
        private String nickname;

        @NotBlank(message = "앱 고유 ID는 필수입니다")
        private String appUniqueId;

        private String languageCode = "ko";
        private String theme = "CLASSIC_BLUE";
        private String deviceInfo;
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class RefreshToken {
        @NotBlank(message = "리프레시 토큰은 필수입니다")
        private String refreshToken;
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class SocialLogin {
        @NotBlank(message = "제공자는 필수입니다")
        private String provider; // "google", "apple"

        @NotBlank(message = "액세스 토큰은 필수입니다")
        private String accessToken;

        @NotBlank(message = "앱 고유 ID는 필수입니다")
        private String appUniqueId;

        private String languageCode = "ko";
        private String theme = "CLASSIC_BLUE";
        private String deviceInfo;
    }
}
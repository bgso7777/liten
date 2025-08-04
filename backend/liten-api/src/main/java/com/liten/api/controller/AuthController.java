package com.liten.api.controller;

import com.liten.api.dto.AuthRequest;
import com.liten.api.dto.AuthResponse;
import com.liten.api.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Authentication", description = "인증 관련 API")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "회원가입", description = "새 사용자를 등록합니다")
    public ResponseEntity<AuthResponse.Register> register(
            @Valid @RequestBody AuthRequest.Register request) {
        try {
            AuthResponse.Register response = authService.register(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("회원가입 실패: {}", e.getMessage(), e);
            throw new RuntimeException("회원가입에 실패했습니다: " + e.getMessage());
        }
    }

    @PostMapping("/login")
    @Operation(summary = "로그인", description = "사용자 로그인을 처리합니다")
    public ResponseEntity<AuthResponse.Login> login(
            @Valid @RequestBody AuthRequest.Login request) {
        try {
            AuthResponse.Login response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("로그인 실패: {}", e.getMessage(), e);
            throw new RuntimeException("로그인에 실패했습니다: " + e.getMessage());
        }
    }

    @PostMapping("/refresh")
    @Operation(summary = "토큰 갱신", description = "액세스 토큰을 갱신합니다")
    public ResponseEntity<AuthResponse.RefreshToken> refreshToken(
            @Valid @RequestBody AuthRequest.RefreshToken request) {
        try {
            AuthResponse.RefreshToken response = authService.refreshToken(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("토큰 갱신 실패: {}", e.getMessage(), e);
            throw new RuntimeException("토큰 갱신에 실패했습니다: " + e.getMessage());
        }
    }

    @PostMapping("/logout")
    @Operation(summary = "로그아웃", description = "사용자 로그아웃을 처리합니다")
    public ResponseEntity<Void> logout(
            @RequestBody(required = false) AuthRequest.RefreshToken request) {
        try {
            String refreshToken = request != null ? request.getRefreshToken() : null;
            authService.logout(refreshToken);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("로그아웃 실패: {}", e.getMessage(), e);
            throw new RuntimeException("로그아웃에 실패했습니다: " + e.getMessage());
        }
    }

    @PostMapping("/social/login")
    @Operation(summary = "소셜 로그인", description = "Google/Apple 소셜 로그인을 처리합니다")
    public ResponseEntity<AuthResponse.Login> socialLogin(
            @Valid @RequestBody AuthRequest.SocialLogin request) {
        // TODO: 소셜 로그인 구현
        throw new RuntimeException("소셜 로그인은 아직 구현되지 않았습니다");
    }
}
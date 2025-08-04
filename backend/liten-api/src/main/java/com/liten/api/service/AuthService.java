package com.liten.api.service;

import com.liten.api.dto.AuthRequest;
import com.liten.api.dto.AuthResponse;
import com.liten.api.model.RefreshToken;
import com.liten.api.model.User;
import com.liten.api.repository.UserRepository;
import com.liten.api.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final RefreshTokenService refreshTokenService;

    public AuthResponse.Register register(AuthRequest.Register request) {
        // 이메일 중복 확인
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("이미 존재하는 이메일입니다: " + request.getEmail());
        }

        // 앱 고유 ID 중복 확인
        if (userRepository.existsByAppUniqueId(request.getAppUniqueId())) {
            throw new RuntimeException("이미 등록된 기기입니다: " + request.getAppUniqueId());
        }

        // 사용자 생성
        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .nickname(request.getNickname())
                .appUniqueId(request.getAppUniqueId())
                .provider(User.AuthProvider.LOCAL)
                .subscriptionType(User.SubscriptionType.FREE)
                .languageCode(request.getLanguageCode())
                .theme(request.getTheme())
                .isActive(true)
                .build();

        user = userRepository.save(user);

        // 토큰 생성
        String accessToken = jwtTokenProvider.generateToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        // 리프레시 토큰 저장
        refreshTokenService.saveRefreshToken(user, refreshToken, request.getDeviceInfo());

        log.info("새 사용자 등록 완료: {}", user.getEmail());

        return AuthResponse.Register.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(86400L) // 24시간
                .user(AuthResponse.UserInfo.from(user))
                .build();
    }

    public AuthResponse.Login login(AuthRequest.Login request) {
        // 인증
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        // 사용자 조회
        User user = userRepository.findActiveByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + request.getEmail()));

        // 마지막 로그인 시간 업데이트
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        // 토큰 생성
        String accessToken = jwtTokenProvider.generateToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        // 리프레시 토큰 저장
        refreshTokenService.saveRefreshToken(user, refreshToken, request.getDeviceInfo());

        log.info("사용자 로그인: {}", user.getEmail());

        return AuthResponse.Login.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(86400L) // 24시간
                .user(AuthResponse.UserInfo.from(user))
                .build();
    }

    public AuthResponse.RefreshToken refreshToken(AuthRequest.RefreshToken request) {
        String refreshTokenValue = request.getRefreshToken();
        
        // 리프레시 토큰 검증
        if (!refreshTokenService.isValidRefreshToken(refreshTokenValue)) {
            throw new RuntimeException("유효하지 않은 리프레시 토큰입니다");
        }

        // 사용자 정보 추출
        String email = jwtTokenProvider.extractUsername(refreshTokenValue);
        User user = userRepository.findActiveByEmail(email)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다: " + email));

        // 새 토큰 생성
        String newAccessToken = jwtTokenProvider.generateToken(user);
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(user);

        // 기존 리프레시 토큰 무효화 및 새 토큰 저장
        refreshTokenService.revokeRefreshToken(refreshTokenValue);
        refreshTokenService.saveRefreshToken(user, newRefreshToken, null);

        return AuthResponse.RefreshToken.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .expiresIn(86400L) // 24시간
                .build();
    }

    public void logout(String refreshToken) {
        if (refreshToken != null) {
            refreshTokenService.revokeRefreshToken(refreshToken);
        }
        log.info("사용자 로그아웃 완료");
    }
}
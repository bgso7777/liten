package com.liten.api.service;

import com.liten.api.model.RefreshToken;
import com.liten.api.model.User;
import com.liten.api.repository.RefreshTokenRepository;
import com.liten.api.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtTokenProvider jwtTokenProvider;

    public void saveRefreshToken(User user, String token, String deviceInfo) {
        RefreshToken refreshToken = RefreshToken.builder()
                .token(token)
                .user(user)
                .expiresAt(LocalDateTime.now().plusDays(7)) // 7일 후 만료
                .deviceInfo(deviceInfo)
                .isRevoked(false)
                .build();

        refreshTokenRepository.save(refreshToken);
        
        // 이전 토큰들 정리 (선택적)
        cleanupExpiredTokens(user);
    }

    public boolean isValidRefreshToken(String token) {
        try {
            return refreshTokenRepository.findByToken(token)
                    .map(RefreshToken::isValid)
                    .orElse(false);
        } catch (Exception e) {
            log.warn("리프레시 토큰 검증 실패: {}", e.getMessage());
            return false;
        }
    }

    public void revokeRefreshToken(String token) {
        refreshTokenRepository.findByToken(token)
                .ifPresent(refreshToken -> {
                    refreshToken.setIsRevoked(true);
                    refreshTokenRepository.save(refreshToken);
                });
    }

    public void revokeAllUserTokens(User user) {
        List<RefreshToken> userTokens = refreshTokenRepository.findValidTokensByUser(user);
        userTokens.forEach(token -> token.setIsRevoked(true));
        refreshTokenRepository.saveAll(userTokens);
    }

    private void cleanupExpiredTokens(User user) {
        List<RefreshToken> expiredTokens = refreshTokenRepository.findExpiredTokensByUser(user);
        if (!expiredTokens.isEmpty()) {
            refreshTokenRepository.deleteAll(expiredTokens);
            log.info("만료된 리프레시 토큰 {} 개 정리 완료", expiredTokens.size());
        }
    }
}
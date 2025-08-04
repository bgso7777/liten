package com.liten.api.repository;

import com.liten.api.model.RefreshToken;
import com.liten.api.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

    Optional<RefreshToken> findByToken(String token);

    @Query("SELECT rt FROM RefreshToken rt WHERE rt.user = :user AND rt.isRevoked = false AND rt.expiresAt > :now AND rt.deletedAt IS NULL")
    List<RefreshToken> findValidTokensByUser(@Param("user") User user, @Param("now") LocalDateTime now);

    default List<RefreshToken> findValidTokensByUser(User user) {
        return findValidTokensByUser(user, LocalDateTime.now());
    }

    @Query("SELECT rt FROM RefreshToken rt WHERE rt.user = :user AND (rt.expiresAt <= :now OR rt.isRevoked = true) AND rt.deletedAt IS NULL")
    List<RefreshToken> findExpiredTokensByUser(@Param("user") User user, @Param("now") LocalDateTime now);

    default List<RefreshToken> findExpiredTokensByUser(User user) {
        return findExpiredTokensByUser(user, LocalDateTime.now());
    }

    @Query("DELETE FROM RefreshToken rt WHERE rt.expiresAt <= :cutoffDate")
    void deleteExpiredTokensBefore(@Param("cutoffDate") LocalDateTime cutoffDate);
}
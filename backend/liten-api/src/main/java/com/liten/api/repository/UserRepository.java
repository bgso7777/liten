package com.liten.api.repository;

import com.liten.api.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    Optional<User> findByAppUniqueId(String appUniqueId);

    Optional<User> findByProviderAndProviderId(User.AuthProvider provider, String providerId);

    @Query("SELECT u FROM User u WHERE u.email = :email AND u.deletedAt IS NULL")
    Optional<User> findActiveByEmail(@Param("email") String email);

    @Query("SELECT u FROM User u WHERE u.appUniqueId = :appUniqueId AND u.deletedAt IS NULL")
    Optional<User> findActiveByAppUniqueId(@Param("appUniqueId") String appUniqueId);

    boolean existsByEmail(String email);

    boolean existsByAppUniqueId(String appUniqueId);

    @Query("SELECT COUNT(u) FROM User u WHERE u.subscriptionType = :subscriptionType AND u.deletedAt IS NULL")
    long countBySubscriptionType(@Param("subscriptionType") User.SubscriptionType subscriptionType);
}
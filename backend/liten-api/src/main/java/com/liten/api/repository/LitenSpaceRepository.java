package com.liten.api.repository;

import com.liten.api.model.LitenSpace;
import com.liten.api.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LitenSpaceRepository extends JpaRepository<LitenSpace, Long> {

    @Query("SELECT ls FROM LitenSpace ls WHERE ls.user = :user AND ls.deletedAt IS NULL ORDER BY ls.sortOrder ASC, ls.createdAt DESC")
    List<LitenSpace> findByUserOrderBySortOrder(@Param("user") User user);

    @Query("SELECT ls FROM LitenSpace ls WHERE ls.user = :user AND ls.isFavorite = true AND ls.deletedAt IS NULL ORDER BY ls.updatedAt DESC")
    List<LitenSpace> findFavoritesByUser(@Param("user") User user);

    @Query("SELECT ls FROM LitenSpace ls WHERE ls.user = :user AND ls.isArchived = false AND ls.deletedAt IS NULL ORDER BY ls.updatedAt DESC")
    List<LitenSpace> findActiveByUser(@Param("user") User user);

    @Query("SELECT ls FROM LitenSpace ls WHERE ls.spaceId = :spaceId AND ls.user = :user AND ls.deletedAt IS NULL")
    Optional<LitenSpace> findBySpaceIdAndUser(@Param("spaceId") Long spaceId, @Param("user") User user);

    @Query("SELECT COUNT(ls) FROM LitenSpace ls WHERE ls.user = :user AND ls.deletedAt IS NULL")
    long countByUser(@Param("user") User user);

    @Query("SELECT ls FROM LitenSpace ls WHERE ls.user = :user AND LOWER(ls.title) LIKE LOWER(CONCAT('%', :keyword, '%')) AND ls.deletedAt IS NULL")
    List<LitenSpace> searchByTitleContaining(@Param("user") User user, @Param("keyword") String keyword);
}
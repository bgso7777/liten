package com.liten.api.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.Set;

@Entity
@Table(name = "liten_spaces")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LitenSpace extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "space_id")
    private Long spaceId;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "description", length = 1000)
    private String description;

    @Column(name = "color", length = 20)
    private String color = "#2196F3";

    @Column(name = "is_favorite")
    private Boolean isFavorite = false;

    @Column(name = "is_archived")
    private Boolean isArchived = false;

    @Column(name = "sort_order")
    private Integer sortOrder = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @OneToMany(mappedBy = "litenSpace", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<AudioContent> audioContents;

    @OneToMany(mappedBy = "litenSpace", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<TextContent> textContents;

    @OneToMany(mappedBy = "litenSpace", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<DrawingContent> drawingContents;

    @OneToMany(mappedBy = "litenSpace", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<SyncTimestamp> syncTimestamps;
}
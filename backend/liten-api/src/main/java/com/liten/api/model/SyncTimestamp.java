package com.liten.api.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sync_timestamps")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncTimestamp extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "sync_id")
    private Long syncId;

    @Column(name = "audio_position_ms", nullable = false)
    private Long audioPositionMs;

    @Column(name = "content_type", length = 20)
    private String contentType;

    @Column(name = "content_id")
    private Long contentId;

    @Column(name = "additional_data", columnDefinition = "JSON")
    private String additionalData;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "space_id", nullable = false)
    private LitenSpace litenSpace;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "audio_id", nullable = false)
    private AudioContent audioContent;
}
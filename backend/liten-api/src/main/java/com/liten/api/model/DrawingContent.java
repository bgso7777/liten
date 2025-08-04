package com.liten.api.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "drawing_contents")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DrawingContent extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "drawing_id")
    private Long drawingId;

    @Column(name = "filename", nullable = false, length = 255)
    private String filename;

    @Column(name = "file_path", nullable = false, length = 500)
    private String filePath;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "width")
    private Integer width;

    @Column(name = "height")
    private Integer height;

    @Column(name = "drawing_data", columnDefinition = "LONGTEXT")
    private String drawingData;

    @Column(name = "thumbnail_path", length = 500)
    private String thumbnailPath;

    @Column(name = "audio_sync_position")
    private Integer audioSyncPosition;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "space_id", nullable = false)
    private LitenSpace litenSpace;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "audio_id")
    private AudioContent audioContent;
}
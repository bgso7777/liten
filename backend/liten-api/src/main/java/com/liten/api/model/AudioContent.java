package com.liten.api.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.Duration;

@Entity
@Table(name = "audio_contents")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AudioContent extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "audio_id")
    private Long audioId;

    @Column(name = "filename", nullable = false, length = 255)
    private String filename;

    @Column(name = "original_filename", length = 255)
    private String originalFilename;

    @Column(name = "file_path", nullable = false, length = 500)
    private String filePath;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "transcription", columnDefinition = "TEXT")
    private String transcription;

    @Column(name = "is_transcribed")
    private Boolean isTranscribed = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "space_id", nullable = false)
    private LitenSpace litenSpace;

    public Duration getDuration() {
        return durationSeconds != null ? Duration.ofSeconds(durationSeconds) : Duration.ZERO;
    }

    public void setDuration(Duration duration) {
        this.durationSeconds = duration != null ? (int) duration.getSeconds() : null;
    }
}
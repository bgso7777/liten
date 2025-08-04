package com.liten.api.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "text_contents")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TextContent extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "text_id")
    private Long textId;

    @Column(name = "content", columnDefinition = "LONGTEXT")
    private String content;

    @Column(name = "plain_text", columnDefinition = "LONGTEXT")
    private String plainText;

    @Enumerated(EnumType.STRING)
    @Column(name = "format_type")
    private FormatType formatType = FormatType.RICH_TEXT;

    @Column(name = "audio_sync_position")
    private Integer audioSyncPosition;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "space_id", nullable = false)
    private LitenSpace litenSpace;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "audio_id")
    private AudioContent audioContent;

    public enum FormatType {
        PLAIN_TEXT, RICH_TEXT, MARKDOWN
    }
}
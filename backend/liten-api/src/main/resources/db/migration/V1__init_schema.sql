-- Liten API Database Schema
-- Version: 1.0.0

-- Users 테이블
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255),
    nickname VARCHAR(50),
    profile_image_url VARCHAR(500),
    app_unique_id VARCHAR(255) NOT NULL UNIQUE,
    provider ENUM('LOCAL', 'GOOGLE', 'APPLE') NOT NULL DEFAULT 'LOCAL',
    provider_id VARCHAR(255),
    subscription_type ENUM('FREE', 'STANDARD', 'PREMIUM') NOT NULL DEFAULT 'FREE',
    subscription_start_date DATETIME,
    subscription_end_date DATETIME,
    language_code VARCHAR(10) DEFAULT 'ko',
    theme VARCHAR(50) DEFAULT 'CLASSIC_BLUE',
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    INDEX idx_email (email),
    INDEX idx_app_unique_id (app_unique_id),
    INDEX idx_provider_provider_id (provider, provider_id),
    INDEX idx_subscription_type (subscription_type),
    INDEX idx_created_at (created_at)
);

-- Refresh Tokens 테이블
CREATE TABLE refresh_tokens (
    token_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(500) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    expires_at DATETIME NOT NULL,
    is_revoked BOOLEAN DEFAULT FALSE,
    device_info VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
);

-- Liten Spaces 테이블
CREATE TABLE liten_spaces (
    space_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    color VARCHAR(20) DEFAULT '#2196F3',
    is_favorite BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_user_favorite (user_id, is_favorite),
    INDEX idx_user_archived (user_id, is_archived),
    INDEX idx_sort_order (sort_order),
    INDEX idx_created_at (created_at)
);

-- Audio Contents 테이블
CREATE TABLE audio_contents (
    audio_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    space_id BIGINT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    duration_seconds INT,
    mime_type VARCHAR(100),
    transcription TEXT,
    is_transcribed BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    FOREIGN KEY (space_id) REFERENCES liten_spaces(space_id) ON DELETE CASCADE,
    INDEX idx_space_id (space_id),
    INDEX idx_filename (filename),
    INDEX idx_created_at (created_at)
);

-- Text Contents 테이블
CREATE TABLE text_contents (
    text_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    space_id BIGINT NOT NULL,
    audio_id BIGINT,
    content LONGTEXT,
    plain_text LONGTEXT,
    format_type ENUM('PLAIN_TEXT', 'RICH_TEXT', 'MARKDOWN') DEFAULT 'RICH_TEXT',
    audio_sync_position INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    FOREIGN KEY (space_id) REFERENCES liten_spaces(space_id) ON DELETE CASCADE,
    FOREIGN KEY (audio_id) REFERENCES audio_contents(audio_id) ON DELETE SET NULL,
    INDEX idx_space_id (space_id),
    INDEX idx_audio_id (audio_id),
    INDEX idx_created_at (created_at)
);

-- Drawing Contents 테이블
CREATE TABLE drawing_contents (
    drawing_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    space_id BIGINT NOT NULL,
    audio_id BIGINT,
    filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    width INT,
    height INT,
    drawing_data LONGTEXT,
    thumbnail_path VARCHAR(500),
    audio_sync_position INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    FOREIGN KEY (space_id) REFERENCES liten_spaces(space_id) ON DELETE CASCADE,
    FOREIGN KEY (audio_id) REFERENCES audio_contents(audio_id) ON DELETE SET NULL,
    INDEX idx_space_id (space_id),
    INDEX idx_audio_id (audio_id),
    INDEX idx_created_at (created_at)
);

-- Sync Timestamps 테이블
CREATE TABLE sync_timestamps (
    sync_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    space_id BIGINT NOT NULL,
    audio_id BIGINT NOT NULL,
    audio_position_ms BIGINT NOT NULL,
    content_type VARCHAR(20),
    content_id BIGINT,
    additional_data JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    
    FOREIGN KEY (space_id) REFERENCES liten_spaces(space_id) ON DELETE CASCADE,
    FOREIGN KEY (audio_id) REFERENCES audio_contents(audio_id) ON DELETE CASCADE,
    INDEX idx_space_audio (space_id, audio_id),
    INDEX idx_audio_position (audio_id, audio_position_ms),
    INDEX idx_content_type_id (content_type, content_id)
);

-- 기본 데이터 삽입
INSERT INTO users (email, password, nickname, app_unique_id, provider, subscription_type, language_code, theme, is_active)
VALUES 
('admin@liten.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMGJwrywTQvpZ.2LJ3JLrMBQ8a', '관리자', 'admin-unique-id', 'LOCAL', 'PREMIUM', 'ko', 'CLASSIC_BLUE', TRUE),
('test@liten.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMGJwrywTQvpZ.2LJ3JLrMBQ8a', '테스트 사용자', 'test-unique-id', 'LOCAL', 'FREE', 'ko', 'CLASSIC_BLUE', TRUE);
# Liten API Server

리튼(Liten) 크로스 플랫폼 노트 앱의 백엔드 API 서버입니다.

## 기술 스택

- **Framework**: Spring Boot 3.2.0
- **Language**: Java 17
- **Database**: MariaDB
- **Authentication**: JWT + Spring Security
- **File Storage**: AWS S3
- **Documentation**: Swagger/OpenAPI 3
- **Build Tool**: Maven

## 주요 기능

### 2차 개발 단계 (유료 버전)
- 사용자 인증 및 관리 (JWT)
- 리튼 공간 관리
- 파일 업로드/다운로드 (AWS S3)
- 클라우드 동기화
- 구독 결제 시스템

## 프로젝트 구조

```
src/main/java/com/liten/api/
├── config/          # 설정 클래스
├── controller/      # REST 컨트롤러
├── dto/            # 데이터 전송 객체
├── exception/      # 예외 처리
├── model/          # JPA 엔티티
├── repository/     # 데이터 접근 계층
├── security/       # 보안 관련
├── service/        # 비즈니스 로직
└── utils/          # 유틸리티
```

## 환경 설정

### 필수 환경 변수
```bash
# 데이터베이스
DB_USERNAME=liten_user
DB_PASSWORD=liten_password

# JWT
JWT_SECRET=your-jwt-secret-key

# AWS S3
AWS_S3_ACCESS_KEY=your-access-key
AWS_S3_SECRET_KEY=your-secret-key
AWS_S3_REGION=ap-northeast-2
AWS_S3_BUCKET=liten-files

# 소셜 로그인 (선택사항)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
APPLE_CLIENT_ID=your-apple-client-id
APPLE_CLIENT_SECRET=your-apple-client-secret
```

### 데이터베이스 설정

MariaDB 설치 및 설정:

```sql
CREATE DATABASE liten_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE liten_dev_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'liten_user'@'localhost' IDENTIFIED BY 'liten_password';
GRANT ALL PRIVILEGES ON liten_db.* TO 'liten_user'@'localhost';
GRANT ALL PRIVILEGES ON liten_dev_db.* TO 'liten_user'@'localhost';
FLUSH PRIVILEGES;
```

## 빌드 및 실행

### 개발 환경
```bash
# 의존성 설치
mvn clean install

# 개발 서버 실행
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 또는
java -jar target/liten-api-1.0.0.jar --spring.profiles.active=dev
```

### 프로덕션 환경
```bash
# 빌드
mvn clean package -Dmaven.test.skip=true

# 실행
java -jar target/liten-api-1.0.0.jar --spring.profiles.active=prod
```

## API 문서

서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:

- Swagger UI: `http://localhost:8080/api/swagger-ui.html`
- OpenAPI JSON: `http://localhost:8080/api/api-docs`

## 주요 엔드포인트

### 인증
- `POST /api/auth/register` - 회원가입
- `POST /api/auth/login` - 로그인
- `POST /api/auth/refresh` - 토큰 갱신
- `POST /api/auth/logout` - 로그아웃

### 상태 확인
- `GET /api/health` - 서버 상태 확인

## 데이터베이스 스키마

주요 테이블:
- `users` - 사용자 정보
- `refresh_tokens` - 리프레시 토큰
- `liten_spaces` - 리튼 공간
- `audio_contents` - 오디오 컨텐츠
- `text_contents` - 텍스트 컨텐츠
- `drawing_contents` - 필기 컨텐츠
- `sync_timestamps` - 동기화 타임스탬프

## 보안

- JWT 토큰 기반 인증
- HTTPS 강제 (프로덕션)
- CORS 설정
- SQL Injection 방지
- 입력 값 검증

## 로깅

- 로그 레벨: DEBUG (개발), INFO (프로덕션)
- 로그 파일: `logs/liten-api.log`
- 구조화된 로깅 지원

## 테스트

```bash
# 단위 테스트 실행
mvn test

# 통합 테스트 실행
mvn verify
```

## 배포

### Docker (예정)
```bash
# 이미지 빌드
docker build -t liten-api:1.0.0 .

# 컨테이너 실행
docker run -p 8080:8080 -e SPRING_PROFILES_ACTIVE=prod liten-api:1.0.0
```

## 개발 가이드

### 새로운 API 추가 시
1. DTO 클래스 생성 (`dto/` 패키지)
2. 컨트롤러 메소드 추가 (`controller/` 패키지)
3. 서비스 로직 구현 (`service/` 패키지)
4. 필요시 Repository 메소드 추가 (`repository/` 패키지)
5. 테스트 코드 작성

### 코드 스타일
- Google Java Style Guide 준수
- Lombok 적극 활용
- JavaDoc 주석 작성
- 예외 처리 필수

## 라이센스

Proprietary - 리튼(Liten) 전용
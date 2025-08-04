/// 앱 전체 설정 관리
class AppConfig {
  // 앱 정보
  static const String appName = '리튼';
  static const String appVersion = '1.0.0';
  static const String appDescription = '크로스 플랫폼 노트 앱';
  
  // 개발 모드 설정
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
  static const bool enableDetailedLogging = isDebug;
  
  // 앱 모드 (1차: 무료버전, 2차: 서버연동 준비)
  static const AppMode currentMode = AppMode.free;
  
  // 로컬 저장소 설정
  static const String localDatabaseName = 'liten_local.db';
  static const int databaseVersion = 1;
  
  // 오디오 설정
  static const String audioFileExtension = '.m4a';
  static const int audioQuality = 192000; // 192kbps
  static const int maxRecordingDurationMinutes = 120; // 2시간
  
  // 이미지 설정
  static const String imageFileExtension = '.jpg';
  static const int imageQuality = 85; // 85% 품질
  static const int maxImageSizeMB = 10;
  
  // 텍스트 설정
  static const int maxTextLength = 100000; // 10만자
  static const String defaultFontFamily = 'NotoSans';
  
  // 광고 설정 (무료 버전용)
  static const bool showAds = currentMode == AppMode.free;
  static const String adBannerId = 'test-banner-id'; // 개발용
  static const int adRefreshIntervalMinutes = 5;
  
  // 서버 설정 (2차 준비용 - 현재 비활성화)
  static const bool enableServerSync = false;
  static const String baseUrl = 'https://api.liten.app';
  static const String apiVersion = 'v1';
  static const Duration httpTimeout = Duration(seconds: 30);
  
  // 캐시 설정
  static const int maxCacheItems = 1000;
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // 로그 설정
  static const int maxLogEntries = 10000;
  static const bool enableCrashReporting = false; // 추후 활성화
}

/// 앱 실행 모드
enum AppMode {
  free,     // 1차: 무료 버전 (로컬 저장, 광고 표시)
  standard, // 2차: 스탠다드 버전 (서버 동기화, 광고 제거)
  premium,  // 3차: 프리미엄 버전 (웹 지원, 고급 기능)
}

/// 앱 모드별 기능 확인
extension AppModeExtension on AppMode {
  bool get isServerSyncEnabled => this != AppMode.free;
  bool get isWebSupportEnabled => this == AppMode.premium;
  bool get isAdsEnabled => this == AppMode.free;
  bool get isAdvancedFeaturesEnabled => this == AppMode.premium;
}
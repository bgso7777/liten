import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/theme_config.dart';
import '../models/liten_space.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../services/audio_service.dart';
import '../services/text_service.dart';
import '../services/drawing_service.dart';

/// 앱 전체 상태 관리 Provider
class AppProvider extends ChangeNotifier {
  // 서비스 인스턴스들
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();
  final AudioService _audioService = AudioService();
  final TextService _textService = TextService();
  final DrawingService _drawingService = DrawingService();

  // 앱 설정
  LitenTheme _currentTheme = LitenTheme.classicBlue;
  Locale _currentLocale = const Locale('ko');
  bool _isInitialized = false;
  bool _isDarkMode = false;

  // Getter들
  LitenTheme get currentTheme => _currentTheme;
  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  
  // 서비스 Getter들
  DatabaseService get databaseService => _databaseService;
  FileService get fileService => _fileService;
  AudioService get audioService => _audioService;
  TextService get textService => _textService;
  DrawingService get drawingService => _drawingService;

  /// 앱 초기화
  Future<void> initializeApp() async {
    try {
      if (_isInitialized) return;

      // SharedPreferences 초기화
      final prefs = await SharedPreferences.getInstance();
      
      // 저장된 설정 불러오기
      await _loadSettings(prefs);
      
      // 데이터베이스 초기화 (가장 먼저)
      if (!kIsWeb) {
        await _databaseService.database;
      } else {
        // 웹 환경에서는 WebStorageService 초기화
        if (AppConfig.enableDetailedLogging) {
          print('웹 환경: SharedPreferences 기반 저장소 사용');
        }
      }
      
      // 웹 환경에서 기본 데이터 생성
      if (kIsWeb) {
        await _createDefaultDataForWeb();
      }
      
      // 파일 시스템 초기화
      await _fileService.initializeAppDirectories();
      
      // 오디오 서비스 초기화
      await _audioService.initialize();
      
      // 임시 파일 정리
      await _fileService.cleanupTempFiles();
      
      _isInitialized = true;
      notifyListeners();

      if (AppConfig.enableDetailedLogging) {
        print('앱 초기화 완료 - 테마: ${_currentTheme.displayName}, 언어: ${_currentLocale.languageCode}');
      }

    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('앱 초기화 중 오류: $e');
      }
      rethrow;
    }
  }

  /// 테마 변경
  Future<void> changeTheme(LitenTheme theme) async {
    try {
      if (_currentTheme == theme) return;

      _currentTheme = theme;
      _isDarkMode = theme == LitenTheme.darkMode;
      
      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', theme.name);
      await prefs.setBool('isDarkMode', _isDarkMode);
      
      notifyListeners();

      if (AppConfig.enableDetailedLogging) {
        print('테마 변경: ${theme.displayName}');
      }
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('테마 변경 중 오류: $e');
      }
    }
  }

  /// 언어 변경
  Future<void> changeLocale(Locale locale) async {
    try {
      if (_currentLocale == locale) return;

      _currentLocale = locale;
      
      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);
      
      notifyListeners();

      if (AppConfig.enableDetailedLogging) {
        print('언어 변경: ${locale.languageCode}');
      }
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('언어 변경 중 오류: $e');
      }
    }
  }

  /// 다크 모드 토글
  Future<void> toggleDarkMode() async {
    try {
      _isDarkMode = !_isDarkMode;
      
      // 다크 모드에 따라 테마 설정
      final newTheme = _isDarkMode ? LitenTheme.darkMode : LitenTheme.classicBlue;
      await changeTheme(newTheme);
      
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('다크 모드 토글 중 오류: $e');
      }
    }
  }

  /// 첫 실행 여부 확인
  Future<bool> isFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.containsKey('isFirstRun');
    } catch (e) {
      return true;
    }
  }

  /// 첫 실행 완료 표시
  Future<void> completeFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstRun', false);
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('첫 실행 완료 표시 중 오류: $e');
      }
    }
  }

  /// 앱 재시작
  Future<void> restartApp() async {
    try {
      _isInitialized = false;
      
      // 모든 서비스 종료
      await _audioService.dispose();
      await _textService.dispose();
      await _drawingService.dispose();
      
      // 다시 초기화
      await initializeApp();
      
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('앱 재시작 중 오류: $e');
      }
      rethrow;
    }
  }

  /// 설정 불러오기
  Future<void> _loadSettings(SharedPreferences prefs) async {
    try {
      // 언어 설정 불러오기
      final languageCode = prefs.getString('language');
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
      } else {
        // 시스템 언어로 초기화
        _currentLocale = _getSystemLocale();
        await prefs.setString('language', _currentLocale.languageCode);
      }

      // 테마 설정 불러오기
      final themeName = prefs.getString('theme');
      if (themeName != null) {
        try {
          _currentTheme = LitenTheme.values.firstWhere(
            (theme) => theme.name == themeName,
          );
        } catch (e) {
          // 저장된 테마가 없으면 언어별 기본 테마 사용
          _currentTheme = ThemeConfig.getDefaultThemeForLocale(_currentLocale.languageCode);
        }
      } else {
        // 언어별 기본 테마 사용
        _currentTheme = ThemeConfig.getDefaultThemeForLocale(_currentLocale.languageCode);
        await prefs.setString('theme', _currentTheme.name);
      }

      // 다크 모드 설정
      _isDarkMode = _currentTheme == LitenTheme.darkMode;
      
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('설정 불러오기 중 오류: $e');
      }
      
      // 기본값으로 초기화
      _currentLocale = const Locale('ko');
      _currentTheme = LitenTheme.classicBlue;
      _isDarkMode = false;
    }
  }

  /// 시스템 언어 감지
  Locale _getSystemLocale() {
    try {
      // 시스템 언어 코드 가져오기 (추후 구현)
      // 현재는 한국어 기본값 사용
      return const Locale('ko');
    } catch (e) {
      return const Locale('ko');
    }
  }

  /// Provider 해제
  @override
  void dispose() {
    // 서비스들은 앱 생명주기와 함께 하므로 여기서 dispose하지 않음
    super.dispose();
  }


  /// 웹 환경용 기본 데이터 생성
  Future<void> _createDefaultDataForWeb() async {
    try {
      // 기존 데이터가 있는지 확인
      final existingSpaces = await _databaseService.getAllLitenSpaces();
      if (existingSpaces.isNotEmpty) {
        return; // 이미 데이터가 있으면 스킵
      }

      // 웹 환경용 기본 리튼 공간 생성
      final defaultSpace = LitenSpace(
        id: 'welcome-${DateTime.now().millisecondsSinceEpoch}',
        title: '🎉 리튼에 오신 것을 환영합니다!',
        description: '웹 버전에서 리튼의 기능을 체험해보세요. 새로운 리튼 공간을 만들어 음성, 텍스트, 그림을 통합 관리할 수 있습니다.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertLitenSpace(defaultSpace);

      if (AppConfig.enableDetailedLogging) {
        print('웹 환경: 기본 리튼 공간 생성 완료');
      }
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('웹 환경 기본 데이터 생성 중 오류: $e');
      }
    }
  }
}

/// 앱 초기화 상태
enum AppInitializationState {
  loading,      // 초기화 중
  completed,    // 초기화 완료
  error,        // 초기화 오류
}

/// 앱 초기화 결과
class AppInitializationResult {
  final AppInitializationState state;
  final String? errorMessage;
  final bool isFirstRun;

  const AppInitializationResult({
    required this.state,
    this.errorMessage,
    this.isFirstRun = false,
  });

  bool get isLoading => state == AppInitializationState.loading;
  bool get isCompleted => state == AppInitializationState.completed;
  bool get hasError => state == AppInitializationState.error;
}
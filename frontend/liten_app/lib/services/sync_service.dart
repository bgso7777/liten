import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../models/liten_space.dart';
import '../models/audio_content.dart';
import '../models/text_content.dart';
import '../models/drawing_content.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'liten_space_service.dart';

/// 동기화 서비스 (2차 서버 연동용 - 현재 비활성화)
class SyncService {
  static SyncService? _instance;
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  final LitenSpaceService _litenSpaceService = LitenSpaceService();

  // 동기화 상태
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;

  // 스트림 컨트롤러
  final StreamController<SyncStatus> _syncStatusController = 
      StreamController<SyncStatus>.broadcast();
  final StreamController<SyncProgress> _syncProgressController = 
      StreamController<SyncProgress>.broadcast();

  SyncService._internal();

  factory SyncService() {
    _instance ??= SyncService._internal();
    return _instance!;
  }

  /// 스트림 getter들
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  Stream<SyncProgress> get syncProgress => _syncProgressController.stream;

  /// 동기화 서비스 사용 가능 여부
  bool get isEnabled => AppConfig.enableServerSync;

  /// 현재 동기화 중인지 확인
  bool get isSyncing => _isSyncing;

  /// 마지막 동기화 시간
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 초기화
  Future<void> initialize() async {
    if (!isEnabled) return;

    try {
      await _apiService.initialize();
      await _loadLastSyncTime();
      
      // 자동 동기화 설정 (로그인 상태일 때만)
      if (_apiService.isLoggedIn) {
        _startAutoSync();
      }

      _syncStatusController.add(SyncStatus.idle);

      if (AppConfig.enableDetailedLogging) {
        print('동기화 서비스 초기화 완료');
      }
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('동기화 서비스 초기화 중 오류: $e');
      }
      _syncStatusController.add(SyncStatus.error);
    }
  }

  /// 수동 동기화 시작
  Future<SyncResult> startSync() async {
    if (!isEnabled) {
      return SyncResult(
        success: false,
        errorMessage: '서버 동기화가 비활성화되어 있습니다',
      );
    }

    if (!_apiService.isLoggedIn) {
      return SyncResult(
        success: false,
        errorMessage: '로그인이 필요합니다',
      );
    }

    if (_isSyncing) {
      return SyncResult(
        success: false,
        errorMessage: '이미 동기화가 진행 중입니다',
      );
    }

    // 네트워크 연결 확인
    final isConnected = await _checkNetworkConnection();
    if (!isConnected) {
      return SyncResult(
        success: false,
        errorMessage: '네트워크 연결을 확인해주세요',
      );
    }

    return await _performSync();
  }

  /// 동기화 실행
  Future<SyncResult> _performSync() async {
    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    
    try {
      // 진행률 초기화
      _syncProgressController.add(SyncProgress(
        currentStep: 0,
        totalSteps: 4,
        message: '동기화 준비 중...',
      ));

      // 1. 리튼 공간 동기화
      _syncProgressController.add(SyncProgress(
        currentStep: 1,
        totalSteps: 4,
        message: '리튼 공간 동기화 중...',
      ));
      
      await _syncSpaces();

      // 2. 오디오 콘텐츠 동기화
      _syncProgressController.add(SyncProgress(
        currentStep: 2,
        totalSteps: 4,
        message: '오디오 콘텐츠 동기화 중...',
      ));
      
      await _syncAudioContents();

      // 3. 텍스트 콘텐츠 동기화
      _syncProgressController.add(SyncProgress(
        currentStep: 3,
        totalSteps: 4,
        message: '텍스트 콘텐츠 동기화 중...',
      ));
      
      await _syncTextContents();

      // 4. 그림 콘텐츠 동기화
      _syncProgressController.add(SyncProgress(
        currentStep: 4,
        totalSteps: 4,
        message: '그림 콘텐츠 동기화 중...',
      ));
      
      await _syncDrawingContents();

      // 동기화 완료
      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();

      _syncStatusController.add(SyncStatus.completed);
      
      return SyncResult(
        success: true,
        syncTime: _lastSyncTime!,
      );

    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
      return SyncResult(
        success: false,
        errorMessage: '동기화 중 오류가 발생했습니다: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// 리튼 공간 동기화
  Future<void> _syncSpaces() async {
    final localSpaces = await _litenSpaceService.getAllSpaces();
    final response = await _apiService.syncSpaces(localSpaces);

    if (response.isSuccess && response.data != null) {
      // 서버에서 받은 공간들로 로컬 업데이트
      for (final serverSpace in response.data!) {
        await _databaseService.insertLitenSpace(serverSpace);
      }
    } else {
      throw SyncException('리튼 공간 동기화 실패: ${response.errorMessage}');
    }
  }

  /// 오디오 콘텐츠 동기화
  Future<void> _syncAudioContents() async {
    final spaces = await _litenSpaceService.getAllSpaces();
    
    for (final space in spaces) {
      final audioContents = await _litenSpaceService.getAudioContents(space.id);
      
      for (final audio in audioContents) {
        if (!audio.isSynced) {
          // 서버에 업로드
          final uploadResponse = await _apiService.uploadAudio(
            audio.filePath,
            space.id,
          );
          
          if (uploadResponse.isSuccess) {
            // 동기화 상태 업데이트
            final updatedAudio = audio.copyWith(isSynced: true);
            await _updateAudioContent(updatedAudio);
          }
        }
      }
    }
  }

  /// 텍스트 콘텐츠 동기화
  Future<void> _syncTextContents() async {
    final spaces = await _litenSpaceService.getAllSpaces();
    
    for (final space in spaces) {
      final textContents = await _litenSpaceService.getTextContents(space.id);
      final response = await _apiService.syncTextContents(space.id, textContents);
      
      if (response.isSuccess && response.data != null) {
        // 서버에서 받은 텍스트들로 로컬 업데이트
        for (final serverText in response.data!) {
          await _updateTextContent(serverText);
        }
      }
    }
  }

  /// 그림 콘텐츠 동기화
  Future<void> _syncDrawingContents() async {
    // TODO: 그림 콘텐츠 동기화 구현
    // 현재는 스킵 (파일 크기가 클 수 있어 별도 처리 필요)
  }

  /// 자동 동기화 시작
  void _startAutoSync() {
    _stopAutoSync(); // 기존 타이머 정리
    
    // 30분마다 자동 동기화
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (!_isSyncing && _apiService.isLoggedIn) {
        startSync();
      }
    });
  }

  /// 자동 동기화 중지
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// 네트워크 연결 확인
  Future<bool> _checkNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) ||
             connectivityResult.contains(ConnectivityResult.wifi) ||
             connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  /// 마지막 동기화 시간 불러오기
  Future<void> _loadLastSyncTime() async {
    try {
      final lastSyncString = await _databaseService.getSetting('last_sync_time');
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      _lastSyncTime = null;
    }
  }

  /// 마지막 동기화 시간 저장
  Future<void> _saveLastSyncTime() async {
    if (_lastSyncTime != null) {
      await _databaseService.setSetting(
        'last_sync_time',
        _lastSyncTime!.toIso8601String(),
      );
    }
  }

  /// 오디오 콘텐츠 업데이트
  Future<void> _updateAudioContent(AudioContent audioContent) async {
    final db = await _databaseService.database;
    await db.update(
      'audio_contents',
      audioContent.toMap(),
      where: 'id = ?',
      whereArgs: [audioContent.id],
    );
  }

  /// 텍스트 콘텐츠 업데이트
  Future<void> _updateTextContent(TextContent textContent) async {
    final db = await _databaseService.database;
    await db.update(
      'text_contents',
      textContent.toMap(),
      where: 'id = ?',
      whereArgs: [textContent.id],
    );
  }

  /// 서비스 종료
  Future<void> dispose() async {
    _stopAutoSync();
    await _syncStatusController.close();
    await _syncProgressController.close();
  }
}

/// 동기화 상태
enum SyncStatus {
  idle,       // 대기 중
  syncing,    // 동기화 중
  completed,  // 완료
  error,      // 오류
}

/// 동기화 진행률
class SyncProgress {
  final int currentStep;
  final int totalSteps;
  final String message;
  final double? percentage;

  const SyncProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.message,
    this.percentage,
  });

  double get progress => totalSteps > 0 ? currentStep / totalSteps : 0.0;
}

/// 동기화 결과
class SyncResult {
  final bool success;
  final String? errorMessage;
  final DateTime? syncTime;
  final int? syncedItemsCount;

  const SyncResult({
    required this.success,
    this.errorMessage,
    this.syncTime,
    this.syncedItemsCount,
  });
}

/// 동기화 예외
class SyncException implements Exception {
  final String message;
  const SyncException(this.message);
  
  @override
  String toString() => 'SyncException: $message';
}
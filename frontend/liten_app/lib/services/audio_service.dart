import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../models/audio_content.dart';
import '../config/app_config.dart';
import 'database_service.dart';
import 'file_service.dart';

/// 음성 녹음/재생 서비스
class AudioService {
  static AudioService? _instance;
  
  final AudioRecorder _recorder = AudioRecorder();
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();

  // 녹음 상태
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;

  // 재생 상태
  AudioContent? _currentPlayingAudio;
  bool _isPlaying = false;

  // 스트림 컨트롤러
  final StreamController<RecordingState> _recordingStateController = 
      StreamController<RecordingState>.broadcast();
  final StreamController<PlaybackState> _playbackStateController = 
      StreamController<PlaybackState>.broadcast();
  final StreamController<Duration> _recordingDurationController = 
      StreamController<Duration>.broadcast();

  AudioService._internal();

  factory AudioService() {
    _instance ??= AudioService._internal();
    return _instance!;
  }

  /// 스트림 getter들
  Stream<RecordingState> get recordingState => _recordingStateController.stream;
  Stream<PlaybackState> get playbackState => _playbackStateController.stream;
  Stream<Duration> get recordingDuration => _recordingDurationController.stream;
  Stream<Duration> get playbackPosition => _player.positionStream;

  /// 현재 상태 getter들
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  AudioContent? get currentPlayingAudio => _currentPlayingAudio;

  /// 초기화
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 기본 초기화만
        _playbackStateController.add(PlaybackState.stopped);
        _recordingStateController.add(RecordingState.stopped);
        if (AppConfig.enableDetailedLogging) {
          print('웹 환경: 오디오 서비스 기본 초기화 완료 (제한된 기능)');
        }
        return;
      }

      // 오디오 세션 설정 (모바일/데스크톱)
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // 재생 상태 리스너 설정
      _player.playbackEventStream.listen((event) {
        _updatePlaybackState();
      });

      _playbackStateController.add(PlaybackState.stopped);
      _recordingStateController.add(RecordingState.stopped);

    } catch (e) {
      throw AudioServiceException('오디오 서비스 초기화에 실패했습니다: $e');
    }
  }

  /// 권한 확인 및 요청
  Future<bool> checkAndRequestPermissions() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 권한을 항상 true로 반환 (브라우저에서 자체 처리)
        return true;
      }

      final microphoneStatus = await Permission.microphone.status;
      
      if (microphoneStatus.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }
      
      return microphoneStatus.isGranted;
    } catch (e) {
      if (kIsWeb) {
        // 웹에서 권한 오류는 무시하고 true 반환
        return true;
      }
      throw AudioServiceException('권한 확인에 실패했습니다: $e');
    }
  }

  /// 녹음 시작
  Future<void> startRecording(String litenSpaceId) async {
    try {
      if (_isRecording) {
        throw AudioServiceException('이미 녹음 중입니다');
      }

      // 권한 확인
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        throw AudioServiceException('마이크 권한이 필요합니다');
      }

      // 임시 파일 경로 생성
      final audioId = _generateAudioId();
      _currentRecordingPath = await _fileService.generateTempFilePath(
        '${audioId}${AppConfig.audioFileExtension}'
      );

      // 녹음 설정
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: AppConfig.audioQuality,
        sampleRate: 44100,
      );

      // 녹음 시작
      await _recorder.start(config, path: _currentRecordingPath!);
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingStateController.add(RecordingState.recording);
      
      // 녹음 시간 타이머 시작
      _startRecordingTimer();

    } catch (e) {
      _currentRecordingPath = null;
      _recordingStartTime = null;
      throw AudioServiceException('녹음 시작에 실패했습니다: $e');
    }
  }

  /// 녹음 중지
  Future<AudioContent?> stopRecording(String litenSpaceId, String title) async {
    try {
      if (!_isRecording || _currentRecordingPath == null) {
        throw AudioServiceException('녹음 중이 아닙니다');
      }

      // 녹음 중지
      await _recorder.stop();
      _stopRecordingTimer();
      
      _isRecording = false;
      _recordingStateController.add(RecordingState.stopped);

      // 녹음 파일 확인
      final tempFile = File(_currentRecordingPath!);
      if (!await tempFile.exists()) {
        throw AudioServiceException('녹음 파일이 생성되지 않았습니다');
      }

      // 녹음 시간 계산
      final duration = DateTime.now().difference(_recordingStartTime!);
      final fileSize = await tempFile.length();

      // 최종 저장 경로로 이동
      final audioId = _generateAudioId();
      final finalPath = await _fileService.generateAudioFilePath(litenSpaceId, audioId);
      await _fileService.moveFile(_currentRecordingPath!, finalPath);

      // AudioContent 생성
      final audioContent = AudioContent(
        id: audioId,
        litenSpaceId: litenSpaceId,
        title: title.trim().isEmpty ? '녹음 ${DateTime.now().toString().substring(5, 16)}' : title,
        filePath: finalPath,
        duration: duration,
        createdAt: _recordingStartTime!,
        updatedAt: DateTime.now(),
        fileSize: fileSize,
      );

      // 데이터베이스에 저장
      await _saveAudioContent(audioContent);

      // 상태 초기화
      _currentRecordingPath = null;
      _recordingStartTime = null;

      return audioContent;

    } catch (e) {
      // 임시 파일 정리
      if (_currentRecordingPath != null) {
        await _fileService.deleteFile(_currentRecordingPath!);
      }
      
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _isRecording = false;
      _recordingStateController.add(RecordingState.stopped);
      
      throw AudioServiceException('녹음 저장에 실패했습니다: $e');
    }
  }

  /// 녹음 취소
  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) return;

      await _recorder.stop();
      _stopRecordingTimer();
      
      // 임시 파일 삭제
      if (_currentRecordingPath != null) {
        await _fileService.deleteFile(_currentRecordingPath!);
      }

      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingStateController.add(RecordingState.stopped);

    } catch (e) {
      throw AudioServiceException('녹음 취소에 실패했습니다: $e');
    }
  }

  /// 오디오 재생
  Future<void> playAudio(AudioContent audioContent) async {
    try {
      // 다른 오디오가 재생 중이면 중지
      if (_isPlaying) {
        await stopAudio();
      }

      // 파일 존재 확인
      if (!await _fileService.fileExists(audioContent.filePath)) {
        throw AudioServiceException('오디오 파일을 찾을 수 없습니다');
      }

      // 오디오 로드 및 재생
      await _player.setFilePath(audioContent.filePath);
      await _player.play();

      _currentPlayingAudio = audioContent;
      _isPlaying = true;
      _updatePlaybackState();

    } catch (e) {
      throw AudioServiceException('오디오 재생에 실패했습니다: $e');
    }
  }

  /// 오디오 재생 일시정지
  Future<void> pauseAudio() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        _isPlaying = false;
        _updatePlaybackState();
      }
    } catch (e) {
      throw AudioServiceException('오디오 일시정지에 실패했습니다: $e');
    }
  }

  /// 오디오 재생 재개
  Future<void> resumeAudio() async {
    try {
      if (!_isPlaying && _currentPlayingAudio != null) {
        await _player.play();
        _isPlaying = true;
        _updatePlaybackState();
      }
    } catch (e) {
      throw AudioServiceException('오디오 재생 재개에 실패했습니다: $e');
    }
  }

  /// 오디오 재생 중지
  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _currentPlayingAudio = null;
      _isPlaying = false;
      _updatePlaybackState();
    } catch (e) {
      throw AudioServiceException('오디오 중지에 실패했습니다: $e');
    }
  }

  /// 특정 위치로 이동
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      throw AudioServiceException('오디오 위치 변경에 실패했습니다: $e');
    }
  }

  /// 리튼 공간의 모든 오디오 조회
  Future<List<AudioContent>> getAudioContents(String litenSpaceId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'audio_contents',
        where: 'litenSpaceId = ?',
        whereArgs: [litenSpaceId],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return AudioContent.fromMap(maps[i]);
      });
    } catch (e) {
      throw AudioServiceException('오디오 목록 조회에 실패했습니다: $e');
    }
  }

  /// 오디오 삭제
  Future<void> deleteAudio(String audioId) async {
    try {
      // 현재 재생 중인 오디오면 중지
      if (_currentPlayingAudio?.id == audioId) {
        await stopAudio();
      }

      // 데이터베이스에서 오디오 정보 조회
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'audio_contents',
        where: 'id = ?',
        whereArgs: [audioId],
      );

      if (maps.isNotEmpty) {
        final audioContent = AudioContent.fromMap(maps.first);
        
        // 파일 삭제
        await _fileService.deleteFile(audioContent.filePath);
        
        // 데이터베이스에서 삭제
        await db.delete(
          'audio_contents',
          where: 'id = ?',
          whereArgs: [audioId],
        );

        // 리튼 공간 콘텐츠 개수 업데이트
        await _databaseService.updateContentCounts(audioContent.litenSpaceId);
      }
    } catch (e) {
      throw AudioServiceException('오디오 삭제에 실패했습니다: $e');
    }
  }

  /// 서비스 종료
  Future<void> dispose() async {
    try {
      // 녹음 중이면 취소
      if (_isRecording) {
        await cancelRecording();
      }

      // 재생 중이면 중지
      if (_isPlaying) {
        await stopAudio();
      }

      // 리소스 해제
      await _recorder.dispose();
      await _player.dispose();
      await _recordingStateController.close();
      await _playbackStateController.close();
      await _recordingDurationController.close();

    } catch (e) {
      print('오디오 서비스 종료 중 오류: $e');
    }
  }

  /// 녹음 시간 타이머 시작
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        _recordingDurationController.add(duration);
        
        // 최대 녹음 시간 체크
        if (duration.inMinutes >= AppConfig.maxRecordingDurationMinutes) {
          timer.cancel();
          // 자동으로 녹음 중지 (별도 처리 필요)
        }
      }
    });
  }

  /// 녹음 시간 타이머 중지
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  /// 재생 상태 업데이트
  void _updatePlaybackState() {
    if (_currentPlayingAudio == null) {
      _playbackStateController.add(PlaybackState.stopped);
    } else if (_isPlaying) {
      _playbackStateController.add(PlaybackState.playing);
    } else {
      _playbackStateController.add(PlaybackState.paused);
    }
  }

  /// 오디오 콘텐츠 데이터베이스 저장
  Future<void> _saveAudioContent(AudioContent audioContent) async {
    final db = await _databaseService.database;
    await db.insert(
      'audio_contents',
      audioContent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // 리튼 공간 콘텐츠 개수 업데이트
    await _databaseService.updateContentCounts(audioContent.litenSpaceId);
  }

  /// 고유한 오디오 ID 생성
  String _generateAudioId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'audio_${timestamp}_$random';
  }
}

/// 녹음 상태
enum RecordingState {
  stopped,    // 중지됨
  recording,  // 녹음 중
  paused,     // 일시정지 (추후 지원)
}

/// 재생 상태
enum PlaybackState {
  stopped,    // 중지됨
  playing,    // 재생 중
  paused,     // 일시정지
  loading,    // 로딩 중
}

/// 오디오 서비스 예외
class AudioServiceException implements Exception {
  final String message;
  const AudioServiceException(this.message);
  
  @override
  String toString() => 'AudioServiceException: $message';
}
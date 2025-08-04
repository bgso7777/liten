import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../config/app_config.dart';

/// 파일 시스템 관리 서비스
class FileService {
  static FileService? _instance;

  FileService._internal();

  factory FileService() {
    _instance ??= FileService._internal();
    return _instance!;
  }

  /// 앱 문서 디렉토리 경로 가져오기
  Future<String> get appDocumentsPath async {
    if (kIsWeb) {
      // 웹 환경에서는 가상 경로 사용
      return '/liten_app_data';
    }
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 리튼 앱 전용 디렉토리 경로
  Future<String> get litenAppPath async {
    final documentsPath = await appDocumentsPath;
    return path.join(documentsPath, 'liten_app');
  }

  /// 리튼 공간별 디렉토리 경로
  Future<String> getSpacePath(String spaceId) async {
    final appPath = await litenAppPath;
    return path.join(appPath, 'spaces', spaceId);
  }

  /// 오디오 파일 디렉토리 경로
  Future<String> getAudioPath(String spaceId) async {
    final spacePath = await getSpacePath(spaceId);
    return path.join(spacePath, 'audio');
  }

  /// 이미지/그림 파일 디렉토리 경로
  Future<String> getImagePath(String spaceId) async {
    final spacePath = await getSpacePath(spaceId);
    return path.join(spacePath, 'images');
  }

  /// 임시 파일 디렉토리 경로
  Future<String> get tempPath async {
    final appPath = await litenAppPath;
    return path.join(appPath, 'temp');
  }

  /// 백업 디렉토리 경로
  Future<String> get backupPath async {
    final appPath = await litenAppPath;
    return path.join(appPath, 'backups');
  }

  /// 리튼 앱 디렉토리 구조 초기화
  Future<void> initializeAppDirectories() async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 디렉토리 생성을 스킵하고 성공으로 처리
        if (AppConfig.enableDetailedLogging) {
          print('웹 환경: 가상 디렉토리 구조 초기화 완료');
        }
        return;
      }

      final appPath = await litenAppPath;
      final tempPath = await this.tempPath;
      final backupPath = await this.backupPath;

      // 메인 디렉토리들 생성
      await _ensureDirectoryExists(appPath);
      await _ensureDirectoryExists(path.join(appPath, 'spaces'));
      await _ensureDirectoryExists(tempPath);
      await _ensureDirectoryExists(backupPath);

      // .gitkeep 파일 생성 (빈 디렉토리 유지용)
      await _createGitKeepFile(path.join(appPath, 'spaces'));
      await _createGitKeepFile(tempPath);
      await _createGitKeepFile(backupPath);

    } catch (e) {
      throw FileServiceException('앱 디렉토리 초기화에 실패했습니다: $e');
    }
  }

  /// 특정 리튼 공간의 디렉토리 생성
  Future<void> createSpaceDirectory(String spaceId) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 디렉토리 생성을 스킵
        if (AppConfig.enableDetailedLogging) {
          print('웹 환경: 리튼 공간 $spaceId 가상 디렉토리 생성 완료');
        }
        return;
      }

      final spacePath = await getSpacePath(spaceId);
      final audioPath = await getAudioPath(spaceId);
      final imagePath = await getImagePath(spaceId);

      await _ensureDirectoryExists(spacePath);
      await _ensureDirectoryExists(audioPath);
      await _ensureDirectoryExists(imagePath);

      // 메타데이터 파일 생성
      await _createSpaceMetadata(spaceId);

    } catch (e) {
      throw FileServiceException('리튼 공간 디렉토리 생성에 실패했습니다: $e');
    }
  }

  /// 리튼 공간 디렉토리 삭제
  Future<void> deleteSpaceDirectory(String spaceId) async {
    try {
      final spacePath = await getSpacePath(spaceId);
      final spaceDir = Directory(spacePath);

      if (await spaceDir.exists()) {
        await spaceDir.delete(recursive: true);
      }
    } catch (e) {
      throw FileServiceException('리튼 공간 디렉토리 삭제에 실패했습니다: $e');
    }
  }

  /// 오디오 파일 저장 경로 생성
  Future<String> generateAudioFilePath(String spaceId, String audioId) async {
    final audioPath = await getAudioPath(spaceId);
    final fileName = '${audioId}${AppConfig.audioFileExtension}';
    return path.join(audioPath, fileName);
  }

  /// 이미지 파일 저장 경로 생성
  Future<String> generateImageFilePath(String spaceId, String imageId) async {
    final imagePath = await getImagePath(spaceId);
    final fileName = '${imageId}${AppConfig.imageFileExtension}';
    return path.join(imagePath, fileName);
  }

  /// 임시 파일 경로 생성
  Future<String> generateTempFilePath(String fileName) async {
    final tempPath = await this.tempPath;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFileName = '${timestamp}_$fileName';
    return path.join(tempPath, tempFileName);
  }

  /// 파일 존재 여부 확인
  Future<bool> fileExists(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 항상 false 반환 (실제 파일 시스템 접근 불가)
        return false;
      }
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 파일 크기 조회
  Future<int> getFileSize(String filePath) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 0 반환
        return 0;
      }
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      throw FileServiceException('파일 크기 조회에 실패했습니다: $e');
    }
  }

  /// 파일 삭제
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileServiceException('파일 삭제에 실패했습니다: $e');
    }
  }

  /// 파일 복사
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        // 대상 디렉토리 생성
        final destinationDir = Directory(path.dirname(destinationPath));
        await destinationDir.create(recursive: true);
        
        await sourceFile.copy(destinationPath);
      } else {
        throw FileServiceException('원본 파일이 존재하지 않습니다: $sourcePath');
      }
    } catch (e) {
      throw FileServiceException('파일 복사에 실패했습니다: $e');
    }
  }

  /// 파일 이동
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      await copyFile(sourcePath, destinationPath);
      await deleteFile(sourcePath);
    } catch (e) {
      throw FileServiceException('파일 이동에 실패했습니다: $e');
    }
  }

  /// 디렉토리 전체 크기 계산
  Future<int> getDirectorySize(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return 0;

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      throw FileServiceException('디렉토리 크기 계산에 실패했습니다: $e');
    }
  }

  /// 앱 전체 사용 용량 조회
  Future<AppStorageInfo> getAppStorageInfo() async {
    try {
      final appPath = await litenAppPath;
      final tempPath = await this.tempPath;
      final backupPath = await this.backupPath;

      final totalSize = await getDirectorySize(appPath);
      final tempSize = await getDirectorySize(tempPath);
      final backupSize = await getDirectorySize(backupPath);
      final dataSize = totalSize - tempSize - backupSize;

      return AppStorageInfo(
        totalSize: totalSize,
        dataSize: dataSize,
        tempSize: tempSize,
        backupSize: backupSize,
      );
    } catch (e) {
      throw FileServiceException('저장소 정보 조회에 실패했습니다: $e');
    }
  }

  /// 임시 파일 정리
  Future<void> cleanupTempFiles() async {
    try {
      final tempPath = await this.tempPath;
      final tempDir = Directory(tempPath);
      
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            // 24시간 이상 된 임시 파일 삭제
            final stat = await entity.stat();
            final age = DateTime.now().difference(stat.modified);
            if (age.inDays >= 1) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      // 임시 파일 정리 실패는 로그만 남기고 예외를 던지지 않음
      print('임시 파일 정리 중 오류 발생: $e');
    }
  }

  /// 디렉토리 존재 확인 및 생성
  Future<void> _ensureDirectoryExists(String directoryPath) async {
    if (kIsWeb) {
      // 웹 환경에서는 실제 디렉토리 생성을 스킵
      return;
    }
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// .gitkeep 파일 생성
  Future<void> _createGitKeepFile(String directoryPath) async {
    if (kIsWeb) {
      // 웹 환경에서는 파일 생성을 스킵
      return;
    }
    final gitKeepPath = path.join(directoryPath, '.gitkeep');
    final gitKeepFile = File(gitKeepPath);
    if (!await gitKeepFile.exists()) {
      await gitKeepFile.writeAsString('# Keep this directory');
    }
  }

  /// 리튼 공간 메타데이터 파일 생성
  Future<void> _createSpaceMetadata(String spaceId) async {
    if (kIsWeb) {
      // 웹 환경에서는 메타데이터 파일 생성을 스킵
      return;
    }
    
    final spacePath = await getSpacePath(spaceId);
    final metadataPath = path.join(spacePath, 'metadata.json');
    final metadataFile = File(metadataPath);
    
    final metadata = {
      'spaceId': spaceId,
      'createdAt': DateTime.now().toIso8601String(),
      'version': AppConfig.appVersion,
    };
    
    await metadataFile.writeAsString(
      '${metadata.toString()}\n',
    );
  }
}

/// 앱 저장소 정보
class AppStorageInfo {
  final int totalSize;     // 전체 크기
  final int dataSize;      // 실제 데이터 크기
  final int tempSize;      // 임시 파일 크기
  final int backupSize;    // 백업 파일 크기

  const AppStorageInfo({
    required this.totalSize,
    required this.dataSize,
    required this.tempSize,
    required this.backupSize,
  });

  /// MB 단위로 변환
  double get totalSizeInMB => totalSize / (1024 * 1024);
  double get dataSizeInMB => dataSize / (1024 * 1024);
  double get tempSizeInMB => tempSize / (1024 * 1024);
  double get backupSizeInMB => backupSize / (1024 * 1024);

  /// 사용률 계산 (0.0 ~ 1.0)
  double get tempUsageRatio => totalSize > 0 ? tempSize / totalSize : 0.0;
  double get backupUsageRatio => totalSize > 0 ? backupSize / totalSize : 0.0;
  double get dataUsageRatio => totalSize > 0 ? dataSize / totalSize : 0.0;
}

/// 파일 서비스 예외
class FileServiceException implements Exception {
  final String message;
  const FileServiceException(this.message);
  
  @override
  String toString() => 'FileServiceException: $message';
}
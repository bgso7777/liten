import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import '../models/liten_space.dart';
import '../models/audio_content.dart';
import '../models/text_content.dart';
import '../models/drawing_content.dart';
import 'database_service.dart';
import 'file_service.dart';

/// 리튼 공간 관리 서비스
class LitenSpaceService {
  static LitenSpaceService? _instance;
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();

  LitenSpaceService._internal();

  factory LitenSpaceService() {
    _instance ??= LitenSpaceService._internal();
    return _instance!;
  }

  /// 모든 리튼 공간 조회
  Future<List<LitenSpace>> getAllSpaces() async {
    try {
      return await _databaseService.getAllLitenSpaces();
    } catch (e) {
      throw LitenSpaceException('리튼 공간 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 새 리튼 공간 생성
  Future<LitenSpace> createSpace({
    required String title,
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final spaceId = _generateSpaceId();
      
      final space = LitenSpace(
        id: spaceId,
        title: title.trim(),
        description: description?.trim(),
        createdAt: now,
        updatedAt: now,
      );

      // 데이터베이스에 저장
      await _databaseService.insertLitenSpace(space);
      
      // 리튼 공간 전용 디렉토리 생성
      await _fileService.createSpaceDirectory(spaceId);
      
      return space;
    } catch (e) {
      throw LitenSpaceException('리튼 공간 생성에 실패했습니다: $e');
    }
  }

  /// 리튼 공간 업데이트
  Future<LitenSpace> updateSpace(LitenSpace space, {
    String? title,
    String? description,
  }) async {
    try {
      final updatedSpace = space.copyWith(
        title: title?.trim(),
        description: description?.trim(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateLitenSpace(updatedSpace);
      return updatedSpace;
    } catch (e) {
      throw LitenSpaceException('리튼 공간 업데이트에 실패했습니다: $e');
    }
  }

  /// 리튼 공간 삭제
  Future<void> deleteSpace(String spaceId) async {
    try {
      // 관련된 모든 파일 삭제
      await _fileService.deleteSpaceDirectory(spaceId);
      
      // 데이터베이스에서 삭제 (CASCADE로 관련 콘텐츠도 함께 삭제)
      await _databaseService.deleteLitenSpace(spaceId);
    } catch (e) {
      throw LitenSpaceException('리튼 공간 삭제에 실패했습니다: $e');
    }
  }

  /// ID로 리튼 공간 조회
  Future<LitenSpace?> getSpaceById(String spaceId) async {
    try {
      return await _databaseService.getLitenSpaceById(spaceId);
    } catch (e) {
      throw LitenSpaceException('리튼 공간을 찾을 수 없습니다: $e');
    }
  }

  /// 리튼 공간의 모든 콘텐츠 조회
  Future<SpaceContents> getSpaceContents(String spaceId) async {
    try {
      final audioContents = await getAudioContents(spaceId);
      final textContents = await getTextContents(spaceId);
      final drawingContents = await getDrawingContents(spaceId);

      return SpaceContents(
        audioContents: audioContents,
        textContents: textContents,
        drawingContents: drawingContents,
      );
    } catch (e) {
      throw LitenSpaceException('리튼 공간 콘텐츠를 불러오는데 실패했습니다: $e');
    }
  }

  /// 오디오 콘텐츠 목록 조회
  Future<List<AudioContent>> getAudioContents(String spaceId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'audio_contents',
        where: 'litenSpaceId = ?',
        whereArgs: [spaceId],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return AudioContent.fromMap(maps[i]);
      });
    } catch (e) {
      throw LitenSpaceException('오디오 콘텐츠를 불러오는데 실패했습니다: $e');
    }
  }

  /// 텍스트 콘텐츠 목록 조회
  Future<List<TextContent>> getTextContents(String spaceId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'text_contents',
        where: 'litenSpaceId = ?',
        whereArgs: [spaceId],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return TextContent.fromMap(maps[i]);
      });
    } catch (e) {
      throw LitenSpaceException('텍스트 콘텐츠를 불러오는데 실패했습니다: $e');
    }
  }

  /// 그림 콘텐츠 목록 조회
  Future<List<DrawingContent>> getDrawingContents(String spaceId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'drawing_contents',
        where: 'litenSpaceId = ?',
        whereArgs: [spaceId],
        orderBy: 'createdAt DESC',
      );

      return List.generate(maps.length, (i) {
        return DrawingContent.fromMap(maps[i]);
      });
    } catch (e) {
      throw LitenSpaceException('그림 콘텐츠를 불러오는데 실패했습니다: $e');
    }
  }

  /// 리튼 공간 검색
  Future<List<LitenSpace>> searchSpaces(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllSpaces();
      }

      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'liten_spaces',
        where: 'title LIKE ? OR description LIKE ?',
        whereArgs: ['%${query.trim()}%', '%${query.trim()}%'],
        orderBy: 'updatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return LitenSpace.fromMap(maps[i]);
      });
    } catch (e) {
      throw LitenSpaceException('리튼 공간 검색에 실패했습니다: $e');
    }
  }

  /// 리튼 공간 복제
  Future<LitenSpace> duplicateSpace(String originalSpaceId, String newTitle) async {
    try {
      final originalSpace = await getSpaceById(originalSpaceId);
      if (originalSpace == null) {
        throw LitenSpaceException('복제할 리튼 공간을 찾을 수 없습니다');
      }

      // 새 공간 생성
      final newSpace = await createSpace(
        title: newTitle,
        description: originalSpace.description,
      );

      // 콘텐츠 복사 (추후 구현)
      // TODO: 오디오, 텍스트, 그림 콘텐츠 복사

      return newSpace;
    } catch (e) {
      throw LitenSpaceException('리튼 공간 복제에 실패했습니다: $e');
    }
  }

  /// 리튼 공간 통계 조회
  Future<SpaceStatistics> getSpaceStatistics(String spaceId) async {
    try {
      final space = await getSpaceById(spaceId);
      if (space == null) {
        throw LitenSpaceException('리튼 공간을 찾을 수 없습니다');
      }

      final contents = await getSpaceContents(spaceId);
      
      // 총 오디오 재생 시간 계산
      final totalAudioDuration = contents.audioContents
          .fold<Duration>(Duration.zero, (sum, audio) => sum + audio.duration);

      // 총 텍스트 글자 수 계산
      final totalTextCharacters = contents.textContents
          .fold<int>(0, (sum, text) => sum + text.characterCount);

      // 총 그림 스트로크 개수 계산
      final totalDrawingStrokes = contents.drawingContents
          .fold<int>(0, (sum, drawing) => sum + drawing.strokeCount);

      return SpaceStatistics(
        space: space,
        totalAudioDuration: totalAudioDuration,
        totalTextCharacters: totalTextCharacters,
        totalDrawingStrokes: totalDrawingStrokes,
        creationDate: space.createdAt,
        lastModifiedDate: space.updatedAt,
      );
    } catch (e) {
      throw LitenSpaceException('리튼 공간 통계 조회에 실패했습니다: $e');
    }
  }

  /// 고유한 리튼 공간 ID 생성
  String _generateSpaceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'liten_${timestamp}_$random';
  }
}

/// 리튼 공간의 모든 콘텐츠
class SpaceContents {
  final List<AudioContent> audioContents;
  final List<TextContent> textContents;
  final List<DrawingContent> drawingContents;

  const SpaceContents({
    required this.audioContents,
    required this.textContents,
    required this.drawingContents,
  });

  /// 총 콘텐츠 개수
  int get totalCount => audioContents.length + textContents.length + drawingContents.length;

  /// 빈 공간인지 확인
  bool get isEmpty => totalCount == 0;
}

/// 리튼 공간 통계
class SpaceStatistics {
  final LitenSpace space;
  final Duration totalAudioDuration;
  final int totalTextCharacters;
  final int totalDrawingStrokes;
  final DateTime creationDate;
  final DateTime lastModifiedDate;

  const SpaceStatistics({
    required this.space,
    required this.totalAudioDuration,
    required this.totalTextCharacters,
    required this.totalDrawingStrokes,
    required this.creationDate,
    required this.lastModifiedDate,
  });

  /// 총 활동 점수 (콘텐츠 활용도 측정)
  int get activityScore {
    int score = 0;
    score += space.audioCount * 10; // 오디오 콘텐츠당 10점
    score += space.textCount * 5;   // 텍스트 콘텐츠당 5점
    score += space.drawingCount * 8; // 그림 콘텐츠당 8점
    score += (totalAudioDuration.inMinutes / 5).round(); // 5분당 1점
    score += (totalTextCharacters / 100).round(); // 100자당 1점
    return score;
  }
}

/// 리튼 공간 서비스 예외
class LitenSpaceException implements Exception {
  final String message;
  const LitenSpaceException(this.message);
  
  @override
  String toString() => 'LitenSpaceException: $message';
}
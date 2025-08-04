import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/text_content.dart';
import '../config/app_config.dart';
import 'database_service.dart';

/// 텍스트 에디터 서비스
class TextService {
  static TextService? _instance;
  final DatabaseService _databaseService = DatabaseService();

  // 편집 히스토리 관리
  final List<TextEditHistory> _editHistory = [];
  int _currentHistoryIndex = -1;
  static const int _maxHistorySize = 50;

  // 자동 저장
  Timer? _autoSaveTimer;
  String? _currentTextId;
  String? _lastSavedContent;

  // 스트림 컨트롤러
  final StreamController<TextContent> _textUpdateController = 
      StreamController<TextContent>.broadcast();
  final StreamController<int> _characterCountController = 
      StreamController<int>.broadcast();

  TextService._internal();

  factory TextService() {
    _instance ??= TextService._internal();
    return _instance!;
  }

  /// 스트림 getter들
  Stream<TextContent> get textUpdates => _textUpdateController.stream;
  Stream<int> get characterCount => _characterCountController.stream;

  /// 새 텍스트 콘텐츠 생성
  Future<TextContent> createTextContent({
    required String litenSpaceId,
    required String title,
    String content = '',
    TextFormat format = TextFormat.plainText,
    List<String> tags = const [],
    Duration? audioTimestamp,
  }) async {
    try {
      final now = DateTime.now();
      final textId = _generateTextId();
      
      final textContent = TextContent(
        id: textId,
        litenSpaceId: litenSpaceId,
        title: title.trim(),
        content: content,
        createdAt: now,
        updatedAt: now,
        format: format,
        tags: tags,
        audioTimestamp: audioTimestamp,
      );

      await _saveTextContent(textContent);
      _textUpdateController.add(textContent);
      
      return textContent;
    } catch (e) {
      throw TextServiceException('텍스트 생성에 실패했습니다: $e');
    }
  }

  /// 텍스트 콘텐츠 조회
  Future<TextContent?> getTextContent(String textId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'text_contents',
        where: 'id = ?',
        whereArgs: [textId],
      );

      if (maps.isNotEmpty) {
        return TextContent.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw TextServiceException('텍스트 조회에 실패했습니다: $e');
    }
  }

  /// 리튼 공간의 모든 텍스트 조회
  Future<List<TextContent>> getTextContents(String litenSpaceId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'text_contents',
        where: 'litenSpaceId = ?',
        whereArgs: [litenSpaceId],
        orderBy: 'updatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return TextContent.fromMap(maps[i]);
      });
    } catch (e) {
      throw TextServiceException('텍스트 목록 조회에 실패했습니다: $e');
    }
  }

  /// 텍스트 콘텐츠 업데이트
  Future<TextContent> updateTextContent(
    TextContent textContent, {
    String? title,
    String? content,
    TextFormat? format,
    List<String>? tags,
    Duration? audioTimestamp,
  }) async {
    try {
      final updatedContent = textContent.copyWith(
        title: title?.trim(),
        content: content,
        updatedAt: DateTime.now(),
        format: format,
        tags: tags,
        audioTimestamp: audioTimestamp,
      );

      await _saveTextContent(updatedContent);
      _textUpdateController.add(updatedContent);
      
      return updatedContent;
    } catch (e) {
      throw TextServiceException('텍스트 업데이트에 실패했습니다: $e');
    }
  }

  /// 텍스트 콘텐츠 삭제
  Future<void> deleteTextContent(String textId) async {
    try {
      final db = await _databaseService.database;
      
      // 리튼 공간 ID 조회 (콘텐츠 개수 업데이트용)
      final textContent = await getTextContent(textId);
      
      await db.delete(
        'text_contents',
        where: 'id = ?',
        whereArgs: [textId],
      );

      // 리튼 공간 콘텐츠 개수 업데이트
      if (textContent != null) {
        await _databaseService.updateContentCounts(textContent.litenSpaceId);
      }

      // 현재 편집 중인 텍스트면 히스토리 초기화
      if (_currentTextId == textId) {
        clearEditHistory();
        _currentTextId = null;
      }

    } catch (e) {
      throw TextServiceException('텍스트 삭제에 실패했습니다: $e');
    }
  }

  /// 텍스트 검색
  Future<List<TextContent>> searchTextContents(
    String litenSpaceId, 
    String query
  ) async {
    try {
      if (query.trim().isEmpty) {
        return await getTextContents(litenSpaceId);
      }

      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'text_contents',
        where: 'litenSpaceId = ? AND (title LIKE ? OR content LIKE ? OR tags LIKE ?)',
        whereArgs: [
          litenSpaceId, 
          '%${query.trim()}%', 
          '%${query.trim()}%',
          '%${query.trim()}%'
        ],
        orderBy: 'updatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return TextContent.fromMap(maps[i]);
      });
    } catch (e) {
      throw TextServiceException('텍스트 검색에 실패했습니다: $e');
    }
  }

  /// 편집 세션 시작
  Future<void> startEditingSession(String textId) async {
    try {
      _currentTextId = textId;
      final textContent = await getTextContent(textId);
      
      if (textContent != null) {
        _lastSavedContent = textContent.content;
        clearEditHistory();
        _addToHistory(textContent.content, 0);
        _startAutoSave();
      }
    } catch (e) {
      throw TextServiceException('편집 세션 시작에 실패했습니다: $e');
    }
  }

  /// 편집 세션 종료
  Future<void> endEditingSession() async {
    try {
      _stopAutoSave();
      
      // 마지막 저장
      if (_currentTextId != null) {
        await _performAutoSave();
      }
      
      _currentTextId = null;
      _lastSavedContent = null;
      clearEditHistory();
    } catch (e) {
      throw TextServiceException('편집 세션 종료에 실패했습니다: $e');
    }
  }

  /// 텍스트 변경 처리
  void onTextChanged(String content, int cursorPosition) {
    try {
      // 글자 수 스트림 업데이트
      _characterCountController.add(content.length);
      
      // 히스토리에 추가 (일정 간격으로)
      if (_shouldAddToHistory(content)) {
        _addToHistory(content, cursorPosition);
      }
      
      // 자동 저장 타이머 재시작
      _restartAutoSave();
      
    } catch (e) {
      print('텍스트 변경 처리 중 오류: $e');
    }
  }

  /// 실행 취소
  String? undo() {
    try {
      if (canUndo()) {
        _currentHistoryIndex--;
        return _editHistory[_currentHistoryIndex].content;
      }
      return null;
    } catch (e) {
      throw TextServiceException('실행 취소에 실패했습니다: $e');
    }
  }

  /// 다시 실행
  String? redo() {
    try {
      if (canRedo()) {
        _currentHistoryIndex++;
        return _editHistory[_currentHistoryIndex].content;
      }
      return null;
    } catch (e) {
      throw TextServiceException('다시 실행에 실패했습니다: $e');
    }
  }

  /// 실행 취소 가능 여부
  bool canUndo() => _currentHistoryIndex > 0;

  /// 다시 실행 가능 여부
  bool canRedo() => _currentHistoryIndex < _editHistory.length - 1;

  /// 편집 히스토리 초기화
  void clearEditHistory() {
    _editHistory.clear();
    _currentHistoryIndex = -1;
  }

  /// 텍스트 통계 조회
  Future<TextStatistics> getTextStatistics(String litenSpaceId) async {
    try {
      final textContents = await getTextContents(litenSpaceId);
      
      int totalCharacters = 0;
      int totalWords = 0;
      int totalTexts = textContents.length;
      int textsWithAudioSync = 0;
      
      final Map<TextFormat, int> formatCounts = {};
      
      for (final text in textContents) {
        totalCharacters += text.characterCount;
        totalWords += text.wordCount;
        
        if (text.hasAudioSync) {
          textsWithAudioSync++;
        }
        
        formatCounts[text.format] = (formatCounts[text.format] ?? 0) + 1;
      }
      
      return TextStatistics(
        totalTexts: totalTexts,
        totalCharacters: totalCharacters,
        totalWords: totalWords,
        textsWithAudioSync: textsWithAudioSync,
        formatCounts: formatCounts,
      );
    } catch (e) {
      throw TextServiceException('텍스트 통계 조회에 실패했습니다: $e');
    }
  }

  /// 텍스트 콘텐츠 데이터베이스 저장
  Future<void> _saveTextContent(TextContent textContent) async {
    final db = await _databaseService.database;
    await db.insert(
      'text_contents',
      textContent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // 리튼 공간 콘텐츠 개수 업데이트
    await _databaseService.updateContentCounts(textContent.litenSpaceId);
  }

  /// 히스토리에 추가할지 판단
  bool _shouldAddToHistory(String content) {
    if (_editHistory.isEmpty) return true;
    
    final lastContent = _editHistory.last.content;
    final contentDiff = (content.length - lastContent.length).abs();
    
    // 글자 수 변화가 5자 이상이거나 5초 이상 경과했을 때
    return contentDiff >= 5 || 
           DateTime.now().difference(_editHistory.last.timestamp).inSeconds >= 5;
  }

  /// 히스토리에 추가
  void _addToHistory(String content, int cursorPosition) {
    // 현재 위치 이후의 히스토리 삭제 (새로운 편집 시작)
    if (_currentHistoryIndex < _editHistory.length - 1) {
      _editHistory.removeRange(_currentHistoryIndex + 1, _editHistory.length);
    }
    
    // 새 히스토리 추가
    _editHistory.add(TextEditHistory(
      content: content,
      timestamp: DateTime.now(),
      cursorPosition: cursorPosition,
    ));
    
    // 최대 크기 유지
    if (_editHistory.length > _maxHistorySize) {
      _editHistory.removeAt(0);
    } else {
      _currentHistoryIndex++;
    }
  }

  /// 자동 저장 시작
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performAutoSave();
    });
  }

  /// 자동 저장 중지
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// 자동 저장 재시작
  void _restartAutoSave() {
    _stopAutoSave();
    _startAutoSave();
  }

  /// 자동 저장 실행
  Future<void> _performAutoSave() async {
    try {
      if (_currentTextId == null || _editHistory.isEmpty) return;
      
      final currentContent = _editHistory.last.content;
      if (currentContent == _lastSavedContent) return;
      
      final textContent = await getTextContent(_currentTextId!);
      if (textContent != null) {
        final updatedContent = textContent.copyWith(
          content: currentContent,
          updatedAt: DateTime.now(),
        );
        
        await _saveTextContent(updatedContent);
        _lastSavedContent = currentContent;
        _textUpdateController.add(updatedContent);
      }
    } catch (e) {
      print('자동 저장 중 오류: $e');
    }
  }

  /// 고유한 텍스트 ID 생성
  String _generateTextId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'text_${timestamp}_$random';
  }

  /// 서비스 종료
  Future<void> dispose() async {
    try {
      await endEditingSession();
      await _textUpdateController.close();
      await _characterCountController.close();
    } catch (e) {
      print('텍스트 서비스 종료 중 오류: $e');
    }
  }
}

/// 텍스트 통계
class TextStatistics {
  final int totalTexts;
  final int totalCharacters;
  final int totalWords;
  final int textsWithAudioSync;
  final Map<TextFormat, int> formatCounts;

  const TextStatistics({
    required this.totalTexts,
    required this.totalCharacters,
    required this.totalWords,
    required this.textsWithAudioSync,
    required this.formatCounts,
  });

  /// 평균 글자 수
  double get averageCharacters => totalTexts > 0 ? totalCharacters / totalTexts : 0;

  /// 평균 단어 수
  double get averageWords => totalTexts > 0 ? totalWords / totalTexts : 0;

  /// 오디오 동기화 비율
  double get audioSyncRatio => totalTexts > 0 ? textsWithAudioSync / totalTexts : 0;
}

/// 텍스트 서비스 예외
class TextServiceException implements Exception {
  final String message;
  const TextServiceException(this.message);
  
  @override
  String toString() => 'TextServiceException: $message';
}
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image/image.dart' as img;

import '../models/drawing_content.dart';
import '../config/app_config.dart';
import 'database_service.dart';
import 'file_service.dart';

/// 그림/필기 서비스
class DrawingService {
  static DrawingService? _instance;
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();

  // 현재 그림 상태
  String? _currentDrawingId;
  List<DrawingStroke> _currentStrokes = [];
  DrawingTool _currentTool = DrawingTool.pen;
  ui.Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;

  // 편집 히스토리 관리
  final List<DrawingEditHistory> _editHistory = [];
  int _currentHistoryIndex = -1;
  static const int _maxHistorySize = 30;

  // 자동 저장
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  // 스트림 컨트롤러
  final StreamController<List<DrawingStroke>> _strokesUpdateController = 
      StreamController<List<DrawingStroke>>.broadcast();
  final StreamController<DrawingTool> _toolChangeController = 
      StreamController<DrawingTool>.broadcast();
  final StreamController<ui.Color> _colorChangeController = 
      StreamController<ui.Color>.broadcast();

  DrawingService._internal();

  factory DrawingService() {
    _instance ??= DrawingService._internal();
    return _instance!;
  }

  /// 스트림 getter들
  Stream<List<DrawingStroke>> get strokesUpdates => _strokesUpdateController.stream;
  Stream<DrawingTool> get toolChanges => _toolChangeController.stream;
  Stream<ui.Color> get colorChanges => _colorChangeController.stream;

  /// 현재 상태 getter들
  List<DrawingStroke> get currentStrokes => List.unmodifiable(_currentStrokes);
  DrawingTool get currentTool => _currentTool;
  ui.Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// 새 그림 콘텐츠 생성
  Future<DrawingContent> createDrawingContent({
    required String litenSpaceId,
    required String title,
    required int canvasWidth,
    required int canvasHeight,
    Duration? audioTimestamp,
  }) async {
    try {
      final now = DateTime.now();
      final drawingId = _generateDrawingId();
      
      // 빈 이미지 파일 경로 생성
      final imagePath = await _fileService.generateImageFilePath(litenSpaceId, drawingId);
      
      final drawingContent = DrawingContent(
        id: drawingId,
        litenSpaceId: litenSpaceId,
        title: title.trim(),
        imagePath: imagePath,
        strokes: [],
        createdAt: now,
        updatedAt: now,
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
        audioTimestamp: audioTimestamp,
      );

      await _saveDrawingContent(drawingContent);
      return drawingContent;
    } catch (e) {
      throw DrawingServiceException('그림 생성에 실패했습니다: $e');
    }
  }

  /// 그림 콘텐츠 조회
  Future<DrawingContent?> getDrawingContent(String drawingId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'drawing_contents',
        where: 'id = ?',
        whereArgs: [drawingId],
      );

      if (maps.isNotEmpty) {
        return DrawingContent.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DrawingServiceException('그림 조회에 실패했습니다: $e');
    }
  }

  /// 리튼 공간의 모든 그림 조회
  Future<List<DrawingContent>> getDrawingContents(String litenSpaceId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'drawing_contents',
        where: 'litenSpaceId = ?',
        whereArgs: [litenSpaceId],
        orderBy: 'updatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return DrawingContent.fromMap(maps[i]);
      });
    } catch (e) {
      throw DrawingServiceException('그림 목록 조회에 실패했습니다: $e');
    }
  }

  /// 그림 편집 세션 시작
  Future<void> startDrawingSession(String drawingId) async {
    try {
      _currentDrawingId = drawingId;
      final drawingContent = await getDrawingContent(drawingId);
      
      if (drawingContent != null) {
        _currentStrokes = List.from(drawingContent.strokes);
        clearEditHistory();
        _addToHistory(_currentStrokes, 'load');
        _hasUnsavedChanges = false;
        _startAutoSave();
        
        _strokesUpdateController.add(_currentStrokes);
      }
    } catch (e) {
      throw DrawingServiceException('그림 편집 세션 시작에 실패했습니다: $e');
    }
  }

  /// 그림 편집 세션 종료
  Future<void> endDrawingSession() async {
    try {
      _stopAutoSave();
      
      // 마지막 저장
      if (_currentDrawingId != null && _hasUnsavedChanges) {
        await _performAutoSave();
      }
      
      _currentDrawingId = null;
      _currentStrokes.clear();
      _hasUnsavedChanges = false;
      clearEditHistory();
    } catch (e) {
      throw DrawingServiceException('그림 편집 세션 종료에 실패했습니다: $e');
    }
  }

  /// 도구 변경
  void setTool(DrawingTool tool) {
    _currentTool = tool;
    _toolChangeController.add(tool);
  }

  /// 색상 변경
  void setColor(ui.Color color) {
    _currentColor = color;
    _colorChangeController.add(color);
  }

  /// 선 굵기 변경
  void setStrokeWidth(double width) {
    _currentStrokeWidth = width.clamp(0.5, 50.0);
  }

  /// 새 스트로크 시작
  void startStroke(DrawingPoint startPoint) {
    if (_currentTool == DrawingTool.eraser) {
      _eraseAtPoint(startPoint);
    } else {
      final stroke = DrawingStroke(
        points: [startPoint],
        tool: _currentTool,
        color: _currentColor,
        strokeWidth: _currentStrokeWidth,
        timestamp: DateTime.now(),
      );
      
      _currentStrokes.add(stroke);
      _hasUnsavedChanges = true;
      _strokesUpdateController.add(_currentStrokes);
    }
  }

  /// 스트로크에 포인트 추가
  void addPointToStroke(DrawingPoint point) {
    if (_currentStrokes.isNotEmpty && _currentTool != DrawingTool.eraser) {
      _currentStrokes.last.points.add(point);
      _strokesUpdateController.add(_currentStrokes);
    } else if (_currentTool == DrawingTool.eraser) {
      _eraseAtPoint(point);
    }
  }

  /// 스트로크 종료
  void endStroke() {
    if (_currentStrokes.isNotEmpty && _currentTool != DrawingTool.eraser) {
      // 빈 스트로크 제거
      if (_currentStrokes.last.isEmpty) {
        _currentStrokes.removeLast();
      } else {
        _addToHistory(_currentStrokes, 'draw');
        _restartAutoSave();
      }
      
      _strokesUpdateController.add(_currentStrokes);
    }
  }

  /// 전체 지우기
  void clearAll() {
    if (_currentStrokes.isNotEmpty) {
      _currentStrokes.clear();
      _hasUnsavedChanges = true;
      _addToHistory(_currentStrokes, 'clear');
      _strokesUpdateController.add(_currentStrokes);
      _restartAutoSave();
    }
  }

  /// 실행 취소
  void undo() {
    if (canUndo()) {
      _currentHistoryIndex--;
      _currentStrokes = List.from(_editHistory[_currentHistoryIndex].strokes);
      _hasUnsavedChanges = true;
      _strokesUpdateController.add(_currentStrokes);
      _restartAutoSave();
    }
  }

  /// 다시 실행
  void redo() {
    if (canRedo()) {
      _currentHistoryIndex++;
      _currentStrokes = List.from(_editHistory[_currentHistoryIndex].strokes);
      _hasUnsavedChanges = true;
      _strokesUpdateController.add(_currentStrokes);
      _restartAutoSave();
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

  /// 그림을 이미지 파일로 저장
  Future<String> saveDrawingAsImage(
    String drawingId,
    GlobalKey repaintBoundaryKey,
  ) async {
    try {
      final drawingContent = await getDrawingContent(drawingId);
      if (drawingContent == null) {
        throw DrawingServiceException('그림을 찾을 수 없습니다');
      }

      // RenderRepaintBoundary에서 이미지 캡처
      final RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png
      );
      
      if (byteData == null) {
        throw DrawingServiceException('이미지 데이터 생성에 실패했습니다');
      }

      // PNG를 JPEG로 변환 (용량 최적화)
      final pngBytes = byteData.buffer.asUint8List();
      final pngImage = img.decodeImage(pngBytes);
      
      if (pngImage == null) {
        throw DrawingServiceException('이미지 디코딩에 실패했습니다');
      }

      final jpegBytes = img.encodeJpg(pngImage, quality: AppConfig.imageQuality);
      
      // 파일로 저장
      final file = File(drawingContent.imagePath);
      await file.writeAsBytes(jpegBytes);
      
      return drawingContent.imagePath;
    } catch (e) {
      throw DrawingServiceException('이미지 저장에 실패했습니다: $e');
    }
  }

  /// 그림 콘텐츠 삭제
  Future<void> deleteDrawingContent(String drawingId) async {
    try {
      final drawingContent = await getDrawingContent(drawingId);
      if (drawingContent == null) return;

      // 이미지 파일 삭제
      await _fileService.deleteFile(drawingContent.imagePath);

      // 데이터베이스에서 삭제
      final db = await _databaseService.database;
      await db.delete(
        'drawing_contents',
        where: 'id = ?',
        whereArgs: [drawingId],
      );

      // 리튼 공간 콘텐츠 개수 업데이트
      await _databaseService.updateContentCounts(drawingContent.litenSpaceId);

      // 현재 편집 중인 그림이면 세션 종료
      if (_currentDrawingId == drawingId) {
        await endDrawingSession();
      }

    } catch (e) {
      throw DrawingServiceException('그림 삭제에 실패했습니다: $e');
    }
  }

  /// 그림 통계 조회
  Future<DrawingStatistics> getDrawingStatistics(String litenSpaceId) async {
    try {
      final drawingContents = await getDrawingContents(litenSpaceId);
      
      int totalDrawings = drawingContents.length;
      int totalStrokes = 0;
      int drawingsWithAudioSync = 0;
      
      final Map<DrawingTool, int> toolUsage = {};
      
      for (final drawing in drawingContents) {
        totalStrokes += drawing.strokeCount;
        
        if (drawing.hasAudioSync) {
          drawingsWithAudioSync++;
        }
        
        // 도구 사용 통계
        for (final stroke in drawing.strokes) {
          toolUsage[stroke.tool] = (toolUsage[stroke.tool] ?? 0) + 1;
        }
      }
      
      return DrawingStatistics(
        totalDrawings: totalDrawings,
        totalStrokes: totalStrokes,
        drawingsWithAudioSync: drawingsWithAudioSync,
        toolUsage: toolUsage,
      );
    } catch (e) {
      throw DrawingServiceException('그림 통계 조회에 실패했습니다: $e');
    }
  }

  /// 특정 지점에서 지우개 동작
  void _eraseAtPoint(DrawingPoint point) {
    final eraseRadius = _currentStrokeWidth * 2;
    bool hasErased = false;
    
    // 역순으로 스트로크 확인 (최신 스트로크부터)
    for (int i = _currentStrokes.length - 1; i >= 0; i--) {
      final stroke = _currentStrokes[i];
      bool shouldRemoveStroke = false;
      
      // 스트로크의 각 점과 거리 확인
      for (final strokePoint in stroke.points) {
        final distance = _calculateDistance(point, strokePoint);
        if (distance <= eraseRadius) {
          shouldRemoveStroke = true;
          break;
        }
      }
      
      if (shouldRemoveStroke) {
        _currentStrokes.removeAt(i);
        hasErased = true;
      }
    }
    
    if (hasErased) {
      _hasUnsavedChanges = true;
      _strokesUpdateController.add(_currentStrokes);
    }
  }

  /// 두 점 사이의 거리 계산
  double _calculateDistance(DrawingPoint p1, DrawingPoint p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// 히스토리에 추가
  void _addToHistory(List<DrawingStroke> strokes, String action) {
    // 현재 위치 이후의 히스토리 삭제
    if (_currentHistoryIndex < _editHistory.length - 1) {
      _editHistory.removeRange(_currentHistoryIndex + 1, _editHistory.length);
    }
    
    // 새 히스토리 추가
    _editHistory.add(DrawingEditHistory(
      strokes: List.from(strokes),
      timestamp: DateTime.now(),
      action: action,
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
      if (_currentDrawingId == null || !_hasUnsavedChanges) return;
      
      final drawingContent = await getDrawingContent(_currentDrawingId!);
      if (drawingContent != null) {
        final updatedContent = drawingContent.copyWith(
          strokes: _currentStrokes,
          updatedAt: DateTime.now(),
        );
        
        await _saveDrawingContent(updatedContent);
        _hasUnsavedChanges = false;
      }
    } catch (e) {
      print('자동 저장 중 오류: $e');
    }
  }

  /// 그림 콘텐츠 데이터베이스 저장
  Future<void> _saveDrawingContent(DrawingContent drawingContent) async {
    final db = await _databaseService.database;
    await db.insert(
      'drawing_contents',
      drawingContent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // 리튼 공간 콘텐츠 개수 업데이트
    await _databaseService.updateContentCounts(drawingContent.litenSpaceId);
  }

  /// 고유한 그림 ID 생성
  String _generateDrawingId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'drawing_${timestamp}_$random';
  }

  /// 서비스 종료
  Future<void> dispose() async {
    try {
      await endDrawingSession();
      await _strokesUpdateController.close();
      await _toolChangeController.close();
      await _colorChangeController.close();
    } catch (e) {
      print('그림 서비스 종료 중 오류: $e');
    }
  }
}

/// 그림 통계
class DrawingStatistics {
  final int totalDrawings;
  final int totalStrokes;
  final int drawingsWithAudioSync;
  final Map<DrawingTool, int> toolUsage;

  const DrawingStatistics({
    required this.totalDrawings,
    required this.totalStrokes,
    required this.drawingsWithAudioSync,
    required this.toolUsage,
  });

  /// 평균 스트로크 수
  double get averageStrokes => totalDrawings > 0 ? totalStrokes / totalDrawings : 0;

  /// 오디오 동기화 비율
  double get audioSyncRatio => totalDrawings > 0 ? drawingsWithAudioSync / totalDrawings : 0;

  /// 가장 많이 사용된 도구
  DrawingTool? get mostUsedTool {
    if (toolUsage.isEmpty) return null;
    
    DrawingTool? mostUsed;
    int maxUsage = 0;
    
    toolUsage.forEach((tool, usage) {
      if (usage > maxUsage) {
        maxUsage = usage;
        mostUsed = tool;
      }
    });
    
    return mostUsed;
  }
}

/// 그림 서비스 예외
class DrawingServiceException implements Exception {
  final String message;
  const DrawingServiceException(this.message);
  
  @override
  String toString() => 'DrawingServiceException: $message';
}
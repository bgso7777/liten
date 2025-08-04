import 'dart:ui' as ui;
import 'dart:math' as math;

/// 그림/필기 콘텐츠 데이터 모델
class DrawingContent {
  final String id;
  final String litenSpaceId;
  final String title;
  final String imagePath; // 저장된 이미지 파일 경로
  final List<DrawingStroke> strokes; // 실제 그림 데이터
  final DateTime createdAt;
  final DateTime updatedAt;
  final int canvasWidth;
  final int canvasHeight;
  final Duration? audioTimestamp; // 음성과 동기화된 시점
  final bool isSynced; // 2차: 서버 동기화 상태

  const DrawingContent({
    required this.id,
    required this.litenSpaceId,
    required this.title,
    required this.imagePath,
    required this.strokes,
    required this.createdAt,
    required this.updatedAt,
    required this.canvasWidth,
    required this.canvasHeight,
    this.audioTimestamp,
    this.isSynced = false,
  });

  /// 데이터베이스 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'litenSpaceId': litenSpaceId,
      'title': title,
      'imagePath': imagePath,
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'audioTimestampMs': audioTimestamp?.inMilliseconds,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Map에서 DrawingContent 생성
  factory DrawingContent.fromMap(Map<String, dynamic> map) {
    final strokesList = map['strokes'] as List<dynamic>? ?? [];
    final audioTimestampMs = map['audioTimestampMs'] as int?;
    
    return DrawingContent(
      id: map['id'] as String,
      litenSpaceId: map['litenSpaceId'] as String,
      title: map['title'] as String,
      imagePath: map['imagePath'] as String,
      strokes: strokesList
          .map((s) => DrawingStroke.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      canvasWidth: map['canvasWidth'] as int,
      canvasHeight: map['canvasHeight'] as int,
      audioTimestamp: audioTimestampMs != null 
          ? Duration(milliseconds: audioTimestampMs)
          : null,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  /// 복사본 생성
  DrawingContent copyWith({
    String? title,
    String? imagePath,
    List<DrawingStroke>? strokes,
    DateTime? updatedAt,
    int? canvasWidth,
    int? canvasHeight,
    Duration? audioTimestamp,
    bool? isSynced,
  }) {
    return DrawingContent(
      id: id,
      litenSpaceId: litenSpaceId,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      strokes: strokes ?? this.strokes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      audioTimestamp: audioTimestamp ?? this.audioTimestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// 스트로크 개수
  int get strokeCount => strokes.length;

  /// 빈 그림인지 확인
  bool get isEmpty => strokes.isEmpty;

  /// 음성과 연결되어 있는지 확인
  bool get hasAudioSync => audioTimestamp != null;

  /// 포맷된 오디오 타임스탬프
  String? get formattedAudioTimestamp {
    if (audioTimestamp == null) return null;
    final totalSeconds = audioTimestamp!.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'DrawingContent(id: $id, title: $title, strokes: $strokeCount)';
  }
}

/// 그림 스트로크 (하나의 연속된 선)
class DrawingStroke {
  final List<DrawingPoint> points;
  final DrawingTool tool;
  final ui.Color color;
  final double strokeWidth;
  final DateTime timestamp;

  const DrawingStroke({
    required this.points,
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => p.toMap()).toList(),
      'tool': tool.name,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory DrawingStroke.fromMap(Map<String, dynamic> map) {
    final pointsList = map['points'] as List<dynamic>;
    
    return DrawingStroke(
      points: pointsList
          .map((p) => DrawingPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      tool: DrawingTool.values.firstWhere(
        (t) => t.name == map['tool'],
        orElse: () => DrawingTool.pen,
      ),
      color: ui.Color(map['color'] as int),
      strokeWidth: map['strokeWidth'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  /// 빈 스트로크인지 확인
  bool get isEmpty => points.isEmpty;

  /// 스트로크의 바운딩 박스
  ui.Rect get boundingBox {
    if (points.isEmpty) return ui.Rect.zero;
    
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;
    
    for (final point in points) {
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }
    
    return ui.Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// 그림 포인트
class DrawingPoint {
  final double x;
  final double y;
  final double pressure; // 압력 (0.0 ~ 1.0)

  const DrawingPoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'pressure': pressure,
    };
  }

  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    return DrawingPoint(
      x: map['x'] as double,
      y: map['y'] as double,
      pressure: map['pressure'] as double? ?? 1.0,
    );
  }

  /// Offset으로 변환
  ui.Offset get offset => ui.Offset(x, y);
}

/// 그림 도구 종류
enum DrawingTool {
  pen('펜'),
  brush('브러시'),
  marker('마커'),
  eraser('지우개');

  const DrawingTool(this.displayName);
  final String displayName;
}

/// 그림 편집 히스토리 (실행 취소/다시 실행용)
class DrawingEditHistory {
  final List<DrawingStroke> strokes;
  final DateTime timestamp;
  final String action; // 'draw', 'erase', 'clear' 등

  const DrawingEditHistory({
    required this.strokes,
    required this.timestamp,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'action': action,
    };
  }

  factory DrawingEditHistory.fromMap(Map<String, dynamic> map) {
    final strokesList = map['strokes'] as List<dynamic>;
    
    return DrawingEditHistory(
      strokes: strokesList
          .map((s) => DrawingStroke.fromMap(s as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      action: map['action'] as String,
    );
  }
}


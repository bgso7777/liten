/// 텍스트 콘텐츠 데이터 모델
class TextContent {
  final String id;
  final String litenSpaceId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TextFormat format;
  final List<String> tags;
  final Duration? audioTimestamp; // 음성과 동기화된 시점
  final bool isSynced; // 2차: 서버 동기화 상태

  const TextContent({
    required this.id,
    required this.litenSpaceId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.format = TextFormat.plainText,
    this.tags = const [],
    this.audioTimestamp,
    this.isSynced = false,
  });

  /// 데이터베이스 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'litenSpaceId': litenSpaceId,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'format': format.name,
      'tags': tags.join(','),
      'audioTimestampMs': audioTimestamp?.inMilliseconds,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Map에서 TextContent 생성
  factory TextContent.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String? ?? '';
    final tags = tagsString.isEmpty 
        ? <String>[] 
        : tagsString.split(',').where((tag) => tag.isNotEmpty).toList();
    
    final audioTimestampMs = map['audioTimestampMs'] as int?;
    
    return TextContent(
      id: map['id'] as String,
      litenSpaceId: map['litenSpaceId'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      format: TextFormat.values.firstWhere(
        (f) => f.name == map['format'],
        orElse: () => TextFormat.plainText,
      ),
      tags: tags,
      audioTimestamp: audioTimestampMs != null 
          ? Duration(milliseconds: audioTimestampMs)
          : null,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  /// 복사본 생성
  TextContent copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    TextFormat? format,
    List<String>? tags,
    Duration? audioTimestamp,
    bool? isSynced,
  }) {
    return TextContent(
      id: id,
      litenSpaceId: litenSpaceId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      format: format ?? this.format,
      tags: tags ?? this.tags,
      audioTimestamp: audioTimestamp ?? this.audioTimestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// 글자 수
  int get characterCount => content.length;

  /// 단어 수 (공백 기준)
  int get wordCount => content.trim().isEmpty 
      ? 0 
      : content.trim().split(RegExp(r'\s+')).length;

  /// 미리보기 텍스트 (첫 100자)
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

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
    return 'TextContent(id: $id, title: $title, chars: $characterCount)';
  }
}

/// 텍스트 포맷 종류
enum TextFormat {
  plainText('일반 텍스트'),
  markdown('마크다운'),
  richText('서식 있는 텍스트');

  const TextFormat(this.displayName);
  final String displayName;
}

/// 텍스트 편집 히스토리 (실행 취소/다시 실행용)
class TextEditHistory {
  final String content;
  final DateTime timestamp;
  final int cursorPosition;

  const TextEditHistory({
    required this.content,
    required this.timestamp,
    required this.cursorPosition,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cursorPosition': cursorPosition,
    };
  }

  factory TextEditHistory.fromMap(Map<String, dynamic> map) {
    return TextEditHistory(
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      cursorPosition: map['cursorPosition'] as int,
    );
  }
}
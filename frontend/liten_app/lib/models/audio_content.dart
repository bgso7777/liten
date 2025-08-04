/// 오디오 콘텐츠 데이터 모델
class AudioContent {
  final String id;
  final String litenSpaceId;
  final String title;
  final String filePath;
  final Duration duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int fileSize; // bytes
  final String? transcription; // 추후 음성인식 결과
  final List<AudioTimestamp> timestamps; // 텍스트/필기와 동기화된 타임스탬프
  final bool isSynced; // 2차: 서버 동기화 상태

  const AudioContent({
    required this.id,
    required this.litenSpaceId,
    required this.title,
    required this.filePath,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
    required this.fileSize,
    this.transcription,
    this.timestamps = const [],
    this.isSynced = false,
  });

  /// 데이터베이스 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'litenSpaceId': litenSpaceId,
      'title': title,
      'filePath': filePath,
      'durationMs': duration.inMilliseconds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'fileSize': fileSize,
      'transcription': transcription,
      'timestamps': timestamps.map((t) => t.toMap()).toList(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Map에서 AudioContent 생성
  factory AudioContent.fromMap(Map<String, dynamic> map) {
    final timestampsList = map['timestamps'] as List<dynamic>? ?? [];
    
    return AudioContent(
      id: map['id'] as String,
      litenSpaceId: map['litenSpaceId'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      duration: Duration(milliseconds: map['durationMs'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      fileSize: map['fileSize'] as int,
      transcription: map['transcription'] as String?,
      timestamps: timestampsList
          .map((t) => AudioTimestamp.fromMap(t as Map<String, dynamic>))
          .toList(),
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  /// 복사본 생성
  AudioContent copyWith({
    String? title,
    String? filePath,
    Duration? duration,
    DateTime? updatedAt,
    int? fileSize,
    String? transcription,
    List<AudioTimestamp>? timestamps,
    bool? isSynced,
  }) {
    return AudioContent(
      id: id,
      litenSpaceId: litenSpaceId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileSize: fileSize ?? this.fileSize,
      transcription: transcription ?? this.transcription,
      timestamps: timestamps ?? this.timestamps,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// 포맷된 재생 시간
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 파일 크기를 MB로 변환
  double get fileSizeInMB => fileSize / (1024 * 1024);

  @override
  String toString() {
    return 'AudioContent(id: $id, title: $title, duration: $formattedDuration)';
  }
}

/// 오디오 타임스탬프 (텍스트/필기와 동기화)
class AudioTimestamp {
  final Duration position; // 오디오 재생 위치
  final String contentId; // 연결된 텍스트 또는 필기 ID
  final String contentType; // 'text' 또는 'drawing'
  final String? note; // 추가 메모

  const AudioTimestamp({
    required this.position,
    required this.contentId,
    required this.contentType,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'positionMs': position.inMilliseconds,
      'contentId': contentId,
      'contentType': contentType,
      'note': note,
    };
  }

  factory AudioTimestamp.fromMap(Map<String, dynamic> map) {
    return AudioTimestamp(
      position: Duration(milliseconds: map['positionMs'] as int),
      contentId: map['contentId'] as String,
      contentType: map['contentType'] as String,
      note: map['note'] as String?,
    );
  }

  /// 포맷된 시간 표시
  String get formattedPosition {
    final totalSeconds = position.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
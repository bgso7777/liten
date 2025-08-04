/// 리튼 공간 데이터 모델
class LitenSpace {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final int audioCount;
  final int textCount;
  final int drawingCount;
  final bool isSynced; // 2차: 서버 동기화 상태

  const LitenSpace({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.audioCount = 0,
    this.textCount = 0,
    this.drawingCount = 0,
    this.isSynced = false,
  });

  /// 데이터베이스 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'thumbnailPath': thumbnailPath,
      'audioCount': audioCount,
      'textCount': textCount,
      'drawingCount': drawingCount,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Map에서 LitenSpace 생성
  factory LitenSpace.fromMap(Map<String, dynamic> map) {
    return LitenSpace(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      thumbnailPath: map['thumbnailPath'] as String?,
      audioCount: map['audioCount'] as int? ?? 0,
      textCount: map['textCount'] as int? ?? 0,
      drawingCount: map['drawingCount'] as int? ?? 0,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  /// 복사본 생성 (일부 필드 수정)
  LitenSpace copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    String? thumbnailPath,
    int? audioCount,
    int? textCount,
    int? drawingCount,
    bool? isSynced,
  }) {
    return LitenSpace(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      audioCount: audioCount ?? this.audioCount,
      textCount: textCount ?? this.textCount,
      drawingCount: drawingCount ?? this.drawingCount,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// 총 콘텐츠 개수
  int get totalContentCount => audioCount + textCount + drawingCount;

  /// 빈 공간인지 확인
  bool get isEmpty => totalContentCount == 0;

  @override
  String toString() {
    return 'LitenSpace(id: $id, title: $title, contentCount: $totalContentCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LitenSpace && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../config/app_config.dart';
import '../models/liten_space.dart';
import '../models/audio_content.dart';
import '../models/text_content.dart';
import '../models/drawing_content.dart';
import 'web_storage_service.dart';

/// 로컬 SQLite 데이터베이스 관리 서비스
class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  static WebStorageService? _webStorage;

  DatabaseService._internal();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  /// 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      await _webStorage!.initialize();
      // 웹에서는 실제 Database 객체를 반환하지 않음
      throw UnsupportedError('웹 환경에서는 WebStorageService를 사용하세요');
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConfig.localDatabaseName);
    
    return await openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// 테이블 생성
  Future<void> _createTables(Database db, int version) async {
    // 리튼 공간 테이블
    await db.execute('''
      CREATE TABLE liten_spaces (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        thumbnailPath TEXT,
        audioCount INTEGER DEFAULT 0,
        textCount INTEGER DEFAULT 0,
        drawingCount INTEGER DEFAULT 0,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // 오디오 콘텐츠 테이블
    await db.execute('''
      CREATE TABLE audio_contents (
        id TEXT PRIMARY KEY,
        litenSpaceId TEXT NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        durationMs INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        fileSize INTEGER NOT NULL,
        transcription TEXT,
        timestamps TEXT, -- JSON 형태로 저장
        isSynced INTEGER DEFAULT 0,
        FOREIGN KEY (litenSpaceId) REFERENCES liten_spaces (id) ON DELETE CASCADE
      )
    ''');

    // 텍스트 콘텐츠 테이블
    await db.execute('''
      CREATE TABLE text_contents (
        id TEXT PRIMARY KEY,
        litenSpaceId TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        format TEXT DEFAULT 'plainText',
        tags TEXT, -- 쉼표로 구분
        audioTimestampMs INTEGER,
        isSynced INTEGER DEFAULT 0,
        FOREIGN KEY (litenSpaceId) REFERENCES liten_spaces (id) ON DELETE CASCADE
      )
    ''');

    // 그림 콘텐츠 테이블
    await db.execute('''
      CREATE TABLE drawing_contents (
        id TEXT PRIMARY KEY,
        litenSpaceId TEXT NOT NULL,
        title TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        strokes TEXT NOT NULL, -- JSON 형태로 저장
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        canvasWidth INTEGER NOT NULL,
        canvasHeight INTEGER NOT NULL,
        audioTimestampMs INTEGER,
        isSynced INTEGER DEFAULT 0,
        FOREIGN KEY (litenSpaceId) REFERENCES liten_spaces (id) ON DELETE CASCADE
      )
    ''');

    // 앱 설정 테이블
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // 인덱스 생성
    await db.execute('CREATE INDEX idx_audio_liten_space ON audio_contents(litenSpaceId)');
    await db.execute('CREATE INDEX idx_text_liten_space ON text_contents(litenSpaceId)');
    await db.execute('CREATE INDEX idx_drawing_liten_space ON drawing_contents(litenSpaceId)');
    await db.execute('CREATE INDEX idx_contents_created_at ON audio_contents(createdAt)');
    await db.execute('CREATE INDEX idx_text_created_at ON text_contents(createdAt)');
    await db.execute('CREATE INDEX idx_drawing_created_at ON drawing_contents(createdAt)');
  }

  /// 데이터베이스 업그레이드
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 추후 스키마 변경 시 사용
    if (oldVersion < 2) {
      // 예: 새로운 컬럼 추가
      // await db.execute('ALTER TABLE liten_spaces ADD COLUMN newColumn TEXT');
    }
  }

  /// 데이터베이스 연결 종료
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 데이터베이스 리셋 (개발용)
  Future<void> reset() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConfig.localDatabaseName);
    
    if (await File(path).exists()) {
      await File(path).delete();
    }
    
    _database = null;
  }

  // === 리튼 공간 관련 메소드 ===

  /// 모든 리튼 공간 조회
  Future<List<LitenSpace>> getAllLitenSpaces() async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      return await _webStorage!.getAllLitenSpaces();
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'liten_spaces',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return LitenSpace.fromMap(maps[i]);
    });
  }

  /// 리튼 공간 생성
  Future<void> insertLitenSpace(LitenSpace space) async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      return await _webStorage!.insertLitenSpace(space);
    }
    
    final db = await database;
    await db.insert(
      'liten_spaces',
      space.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 리튼 공간 업데이트
  Future<void> updateLitenSpace(LitenSpace space) async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      return await _webStorage!.updateLitenSpace(space);
    }
    
    final db = await database;
    await db.update(
      'liten_spaces',
      space.toMap(),
      where: 'id = ?',
      whereArgs: [space.id],
    );
  }

  /// 리튼 공간 삭제
  Future<void> deleteLitenSpace(String id) async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      return await _webStorage!.deleteLitenSpace(id);
    }
    
    final db = await database;
    await db.delete(
      'liten_spaces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ID로 리튼 공간 조회
  Future<LitenSpace?> getLitenSpaceById(String id) async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      return await _webStorage!.getLitenSpaceById(id);
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'liten_spaces',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return LitenSpace.fromMap(maps.first);
    }
    return null;
  }

  // === 콘텐츠 개수 업데이트 ===

  /// 리튼 공간의 콘텐츠 개수 업데이트
  Future<void> updateContentCounts(String litenSpaceId) async {
    final db = await database;
    
    // 각 콘텐츠 타입별 개수 조회
    final audioCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM audio_contents WHERE litenSpaceId = ?',
      [litenSpaceId]
    )) ?? 0;
    
    final textCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM text_contents WHERE litenSpaceId = ?',
      [litenSpaceId]
    )) ?? 0;
    
    final drawingCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM drawing_contents WHERE litenSpaceId = ?',
      [litenSpaceId]
    )) ?? 0;

    // 리튼 공간 업데이트
    await db.update(
      'liten_spaces',
      {
        'audioCount': audioCount,
        'textCount': textCount,
        'drawingCount': drawingCount,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [litenSpaceId],
    );
  }

  // === 설정 관련 메소드 ===

  /// 설정 값 저장
  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      return await _webStorage!.setSetting(key, value);
    }
    
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 설정 값 조회
  Future<String?> getSetting(String key) async {
    if (kIsWeb) {
      _webStorage ??= WebStorageService();
      return await _webStorage!.getSetting(key);
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  /// 모든 설정 조회
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('app_settings');
    
    final Map<String, String> settings = {};
    for (final map in maps) {
      settings[map['key'] as String] = map['value'] as String;
    }
    
    return settings;
  }
}
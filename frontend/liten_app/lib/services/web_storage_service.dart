import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/liten_space.dart';
import '../models/audio_content.dart';
import '../models/text_content.dart';
import '../models/drawing_content.dart';

/// 웹 환경용 저장소 서비스 (SQLite 대체)
class WebStorageService {
  static WebStorageService? _instance;
  SharedPreferences? _prefs;

  WebStorageService._internal();

  factory WebStorageService() {
    _instance ??= WebStorageService._internal();
    return _instance!;
  }

  /// 초기화
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 모든 리튼 공간 조회
  Future<List<LitenSpace>> getAllLitenSpaces() async {
    await initialize();
    
    final spacesJson = _prefs!.getStringList('liten_spaces') ?? [];
    return spacesJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return LitenSpace.fromMap(map);
    }).toList();
  }

  /// 리튼 공간 저장
  Future<void> insertLitenSpace(LitenSpace space) async {
    await initialize();
    
    final existingSpaces = await getAllLitenSpaces();
    final updatedSpaces = [...existingSpaces, space];
    
    final spacesJson = updatedSpaces.map((space) => jsonEncode(space.toMap())).toList();
    await _prefs!.setStringList('liten_spaces', spacesJson);
  }

  /// 리튼 공간 업데이트
  Future<void> updateLitenSpace(LitenSpace space) async {
    await initialize();
    
    final existingSpaces = await getAllLitenSpaces();
    final updatedSpaces = existingSpaces.map((existingSpace) {
      return existingSpace.id == space.id ? space : existingSpace;
    }).toList();
    
    final spacesJson = updatedSpaces.map((space) => jsonEncode(space.toMap())).toList();
    await _prefs!.setStringList('liten_spaces', spacesJson);
  }

  /// 리튼 공간 삭제
  Future<void> deleteLitenSpace(String spaceId) async {
    await initialize();
    
    final existingSpaces = await getAllLitenSpaces();
    final updatedSpaces = existingSpaces.where((space) => space.id != spaceId).toList();
    
    final spacesJson = updatedSpaces.map((space) => jsonEncode(space.toMap())).toList();
    await _prefs!.setStringList('liten_spaces', spacesJson);
    
    // 관련 콘텐츠도 삭제
    await _deleteRelatedContent(spaceId);
  }

  /// ID로 리튼 공간 조회
  Future<LitenSpace?> getLitenSpaceById(String spaceId) async {
    final spaces = await getAllLitenSpaces();
    try {
      return spaces.firstWhere((space) => space.id == spaceId);
    } catch (e) {
      return null;
    }
  }

  /// 오디오 콘텐츠 조회
  Future<List<AudioContent>> getAudioContentsBySpaceId(String spaceId) async {
    await initialize();
    
    final key = 'audio_contents_$spaceId';
    final contentsJson = _prefs!.getStringList(key) ?? [];
    
    return contentsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AudioContent.fromMap(map);
    }).toList();
  }

  /// 텍스트 콘텐츠 조회
  Future<List<TextContent>> getTextContentsBySpaceId(String spaceId) async {
    await initialize();
    
    final key = 'text_contents_$spaceId';
    final contentsJson = _prefs!.getStringList(key) ?? [];
    
    return contentsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return TextContent.fromMap(map);
    }).toList();
  }

  /// 그림 콘텐츠 조회
  Future<List<DrawingContent>> getDrawingContentsBySpaceId(String spaceId) async {
    await initialize();
    
    final key = 'drawing_contents_$spaceId';
    final contentsJson = _prefs!.getStringList(key) ?? [];
    
    return contentsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return DrawingContent.fromMap(map);
    }).toList();
  }

  /// 설정 저장
  Future<void> setSetting(String key, String value) async {
    await initialize();
    await _prefs!.setString('setting_$key', value);
  }

  /// 설정 조회
  Future<String?> getSetting(String key) async {
    await initialize();
    return _prefs!.getString('setting_$key');
  }

  /// 관련 콘텐츠 삭제
  Future<void> _deleteRelatedContent(String spaceId) async {
    await initialize();
    
    final keys = [
      'audio_contents_$spaceId',
      'text_contents_$spaceId',
      'drawing_contents_$spaceId',
    ];
    
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// 모든 데이터 삭제 (디버그용)
  Future<void> clearAllData() async {
    await initialize();
    
    final keys = _prefs!.getKeys().where((key) => 
      key.startsWith('liten_') || 
      key.startsWith('audio_contents_') || 
      key.startsWith('text_contents_') || 
      key.startsWith('drawing_contents_') ||
      key.startsWith('setting_')
    ).toList();
    
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }
}
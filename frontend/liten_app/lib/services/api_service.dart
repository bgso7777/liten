import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/liten_space.dart';
import '../models/audio_content.dart';
import '../models/text_content.dart';
import '../models/drawing_content.dart';

/// API 서비스 (2차 서버 연동용 - 현재 비활성화)
class ApiService {
  static ApiService? _instance;
  final http.Client _httpClient = http.Client();
  
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiration;

  ApiService._internal();

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  /// API 서비스 사용 가능 여부
  bool get isEnabled => AppConfig.enableServerSync;

  /// 로그인 상태 확인
  bool get isLoggedIn => _accessToken != null && !_isTokenExpired();

  /// 기본 헤더 생성
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
  };

  /// 인증 헤더 포함
  Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// 초기화 - 저장된 토큰 불러오기
  Future<void> initialize() async {
    if (!isEnabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      
      final expirationString = prefs.getString('token_expiration');
      if (expirationString != null) {
        _tokenExpiration = DateTime.parse(expirationString);
      }

      // 토큰이 만료되었으면 갱신 시도
      if (_isTokenExpired() && _refreshToken != null) {
        await _refreshAccessToken();
      }
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('API 서비스 초기화 중 오류: $e');
      }
    }
  }

  /// 회원가입
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    if (!isEnabled) {
      return ApiResponse.error('서버 연동이 비활성화되어 있습니다');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('${AppConfig.baseUrl}/api/${AppConfig.apiVersion}/auth/register'),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'deviceId': deviceId,
          'appVersion': AppConfig.appVersion,
        }),
      ).timeout(AppConfig.httpTimeout);

      return _handleResponse<Map<String, dynamic>>(response);
    } catch (e) {
      return ApiResponse.error('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  /// 로그인
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    if (!isEnabled) {
      return ApiResponse.error('서버 연동이 비활성화되어 있습니다');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('${AppConfig.baseUrl}/api/${AppConfig.apiVersion}/auth/login'),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'deviceId': deviceId,
        }),
      ).timeout(AppConfig.httpTimeout);

      final result = _handleResponse<Map<String, dynamic>>(response);
      
      if (result.isSuccess && result.data != null) {
        await _saveTokens(result.data!);
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('로그인 중 오류가 발생했습니다: $e');
    }
  }

  /// 로그아웃
  Future<ApiResponse<void>> logout() async {
    if (!isEnabled) {
      return ApiResponse.error('서버 연동이 비활성화되어 있습니다');
    }

    try {
      await _httpClient.post(
        Uri.parse('${AppConfig.baseUrl}/api/${AppConfig.apiVersion}/auth/logout'),
        headers: _authHeaders,
        body: jsonEncode({
          'refreshToken': _refreshToken,
        }),
      ).timeout(AppConfig.httpTimeout);

      await _clearTokens();
      return ApiResponse.success(null);
    } catch (e) {
      await _clearTokens(); // 오류가 발생해도 로컬 토큰은 삭제
      return ApiResponse.error('로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  /// 리튼 공간 동기화
  Future<ApiResponse<List<LitenSpace>>> syncSpaces(List<LitenSpace> localSpaces) async {
    if (!isEnabled || !isLoggedIn) {
      return ApiResponse.error('로그인이 필요합니다');
    }

    try {
      await _ensureValidToken();

      final response = await _httpClient.post(
        Uri.parse('${AppConfig.baseUrl}/api/${AppConfig.apiVersion}/spaces/sync'),
        headers: _authHeaders,
        body: jsonEncode({
          'spaces': localSpaces.map((space) => space.toMap()).toList(),
        }),
      ).timeout(AppConfig.httpTimeout);

      final result = _handleResponse<List<dynamic>>(response);
      
      if (result.isSuccess && result.data != null) {
        final spaces = result.data!
            .map((data) => LitenSpace.fromMap(data as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(spaces);
      }
      
      return ApiResponse.error(result.errorMessage ?? '동기화 실패');
    } catch (e) {
      return ApiResponse.error('리튼 공간 동기화 중 오류가 발생했습니다: $e');
    }
  }

  /// 오디오 콘텐츠 업로드
  Future<ApiResponse<String>> uploadAudio(String filePath, String spaceId) async {
    if (!isEnabled || !isLoggedIn) {
      return ApiResponse.error('로그인이 필요합니다');
    }

    try {
      await _ensureValidToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/${AppConfig.apiVersion}/content/audio'),
      );

      request.headers.addAll(_authHeaders);
      request.fields['spaceId'] = spaceId;
      request.files.add(await http.MultipartFile.fromPath('audio', filePath));

      final streamedResponse = await request.send().timeout(AppConfig.httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      final result = _handleResponse<Map<String, dynamic>>(response);
      
      if (result.isSuccess && result.data != null) {
        return ApiResponse.success(result.data!['url'] as String);
      }
      
      return ApiResponse.error(result.errorMessage ?? '오디오 업로드 실패');
    } catch (e) {
      return ApiResponse.error('오디오 업로드 중 오류가 발생했습니다: $e');
    }
  }

  /// 텍스트 콘텐츠 동기화
  Future<ApiResponse<List<TextContent>>> syncTextContents(
    String spaceId,
    List<TextContent> localTexts,
  ) async {
    if (!isEnabled || !isLoggedIn) {
      return ApiResponse.error('로그인이 필요합니다');
    }

    try {
      await _ensureValidToken();

      final response = await _httpClient.post(
        Uri.parse('${AppConfig.baseUrl}/api/${AppConfig.apiVersion}/content/text/sync'),
        headers: _authHeaders,
        body: jsonEncode({
          'spaceId': spaceId,
          'texts': localTexts.map((text) => text.toMap()).toList(),
        }),
      ).timeout(AppConfig.httpTimeout);

      final result = _handleResponse<List<dynamic>>(response);
      
      if (result.isSuccess && result.data != null) {
        final texts = result.data!
            .map((data) => TextContent.fromMap(data as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(texts);
      }
      
      return ApiResponse.error(result.errorMessage ?? '텍스트 동기화 실패');
    } catch (e) {
      return ApiResponse.error('텍스트 동기화 중 오류가 발생했습니다: $e');
    }
  }

  /// 토큰 갱신
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('${AppConfig.baseUrl}/api/${AppConfig.apiVersion}/auth/refresh'),
        headers: _baseHeaders,
        body: jsonEncode({
          'refreshToken': _refreshToken,
        }),
      ).timeout(AppConfig.httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(data);
        return true;
      }
    } catch (e) {
      if (AppConfig.enableDetailedLogging) {
        print('토큰 갱신 중 오류: $e');
      }
    }

    await _clearTokens();
    return false;
  }

  /// 유효한 토큰 확보
  Future<void> _ensureValidToken() async {
    if (_isTokenExpired()) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        throw ApiException('인증 토큰이 만료되었습니다. 다시 로그인해주세요.');
      }
    }
  }

  /// 토큰 만료 확인
  bool _isTokenExpired() {
    if (_tokenExpiration == null) return true;
    return DateTime.now().isAfter(_tokenExpiration!.subtract(const Duration(minutes: 5)));
  }

  /// 토큰 저장
  Future<void> _saveTokens(Map<String, dynamic> tokenData) async {
    _accessToken = tokenData['accessToken'] as String?;
    _refreshToken = tokenData['refreshToken'] as String?;
    
    final expiresIn = tokenData['expiresIn'] as int?;
    if (expiresIn != null) {
      _tokenExpiration = DateTime.now().add(Duration(seconds: expiresIn));
    }

    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
    if (_tokenExpiration != null) {
      await prefs.setString('token_expiration', _tokenExpiration!.toIso8601String());
    }
  }

  /// 토큰 삭제
  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiration = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiration');
  }

  /// HTTP 응답 처리
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data as T);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = errorData?['message'] as String? ?? 
                       'HTTP ${response.statusCode}';
        return ApiResponse.error(message);
      }
    } catch (e) {
      return ApiResponse.error('응답 처리 중 오류가 발생했습니다: $e');
    }
  }

  /// 서비스 종료
  void dispose() {
    _httpClient.close();
  }
}

/// API 응답 래퍼
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse._(isSuccess: false, errorMessage: message);
  }

  bool get isError => !isSuccess;
}

/// API 예외
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}
import 'package:flutter/material.dart';

import '../models/liten_space.dart';
import '../services/liten_space_service.dart';
import '../config/app_config.dart';

/// 리튼 공간 상태 관리 Provider
class LitenSpaceProvider extends ChangeNotifier {
  final LitenSpaceService _litenSpaceService = LitenSpaceService();

  // 상태 변수들
  List<LitenSpace> _spaces = [];
  List<LitenSpace> _filteredSpaces = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  LitenSpaceSortType _sortType = LitenSpaceSortType.updatedAt;
  bool _sortDescending = true;

  // Getter들
  List<LitenSpace> get spaces => _filteredSpaces;
  List<LitenSpace> get allSpaces => _spaces;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  LitenSpaceSortType get sortType => _sortType;
  bool get sortDescending => _sortDescending;
  bool get isEmpty => _spaces.isEmpty;
  int get spacesCount => _spaces.length;

  /// 모든 리튼 공간 로드
  Future<void> loadSpaces() async {
    try {
      _setLoading(true);
      _clearError();

      _spaces = await _litenSpaceService.getAllSpaces();
      _applyFilterAndSort();

      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 ${_spaces.length}개 로드 완료');
      }

    } catch (e) {
      _setError('리튼 공간을 불러오는데 실패했습니다: $e');
      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 로드 오류: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 새 리튼 공간 생성
  Future<LitenSpace?> createSpace({
    required String title,
    String? description,
  }) async {
    try {
      _clearError();

      if (title.trim().isEmpty) {
        _setError('리튼 공간 이름을 입력해주세요');
        return null;
      }

      final newSpace = await _litenSpaceService.createSpace(
        title: title,
        description: description,
      );

      _spaces.insert(0, newSpace);
      _applyFilterAndSort();

      if (AppConfig.enableDetailedLogging) {
        print('새 리튼 공간 생성: ${newSpace.title}');
      }

      return newSpace;

    } catch (e) {
      _setError('리튼 공간 생성에 실패했습니다: $e');
      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 생성 오류: $e');
      }
      return null;
    }
  }

  /// 리튼 공간 업데이트
  Future<bool> updateSpace(
    String spaceId, {
    String? title,
    String? description,
  }) async {
    try {
      _clearError();

      final space = _findSpaceById(spaceId);
      if (space == null) {
        _setError('리튼 공간을 찾을 수 없습니다');
        return false;
      }

      if (title != null && title.trim().isEmpty) {
        _setError('리튼 공간 이름을 입력해주세요');
        return false;
      }

      final updatedSpace = await _litenSpaceService.updateSpace(
        space,
        title: title,
        description: description,
      );

      _updateSpaceInList(updatedSpace);
      _applyFilterAndSort();

      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 업데이트: ${updatedSpace.title}');
      }

      return true;

    } catch (e) {
      _setError('리튼 공간 업데이트에 실패했습니다: $e');
      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 업데이트 오류: $e');
      }
      return false;
    }
  }

  /// 리튼 공간 삭제
  Future<bool> deleteSpace(String spaceId) async {
    try {
      _clearError();

      final space = _findSpaceById(spaceId);
      if (space == null) {
        _setError('리튼 공간을 찾을 수 없습니다');
        return false;
      }

      await _litenSpaceService.deleteSpace(spaceId);
      
      _spaces.removeWhere((space) => space.id == spaceId);
      _applyFilterAndSort();

      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 삭제: ${space.title}');
      }

      return true;

    } catch (e) {
      _setError('리튼 공간 삭제에 실패했습니다: $e');
      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 삭제 오류: $e');
      }
      return false;
    }
  }

  /// 리튼 공간 검색
  Future<void> searchSpaces(String query) async {
    try {
      _searchQuery = query.trim();
      
      if (_searchQuery.isEmpty) {
        _filteredSpaces = List.from(_spaces);
      } else {
        _filteredSpaces = _spaces.where((space) {
          return space.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (space.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();
      }

      _applySorting();

      if (AppConfig.enableDetailedLogging) {
        print('검색 결과: ${_filteredSpaces.length}개 (검색어: "$_searchQuery")');
      }

    } catch (e) {
      _setError('검색 중 오류가 발생했습니다: $e');
      if (AppConfig.enableDetailedLogging) {
        print('검색 오류: $e');
      }
    }
  }

  /// 정렬 방식 변경
  void changeSortType(LitenSpaceSortType sortType, {bool? descending}) {
    _sortType = sortType;
    if (descending != null) {
      _sortDescending = descending;
    }
    
    _applySorting();

    if (AppConfig.enableDetailedLogging) {
      print('정렬 방식 변경: ${sortType.name} (내림차순: $_sortDescending)');
    }
  }

  /// 정렬 순서 토글
  void toggleSortOrder() {
    _sortDescending = !_sortDescending;
    _applySorting();
  }

  /// 리튼 공간 복제
  Future<LitenSpace?> duplicateSpace(String spaceId, String newTitle) async {
    try {
      _clearError();

      if (newTitle.trim().isEmpty) {
        _setError('새 리튼 공간 이름을 입력해주세요');
        return null;
      }

      final duplicatedSpace = await _litenSpaceService.duplicateSpace(
        spaceId,
        newTitle,
      );

      _spaces.insert(0, duplicatedSpace);
      _applyFilterAndSort();

      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 복제: ${duplicatedSpace.title}');
      }

      return duplicatedSpace;

    } catch (e) {
      _setError('리튼 공간 복제에 실패했습니다: $e');
      if (AppConfig.enableDetailedLogging) {
        print('리튼 공간 복제 오류: $e');
      }
      return null;
    }
  }

  /// 리튼 공간 새로고침
  Future<void> refreshSpaces() async {
    await loadSpaces();
  }

  /// 특정 리튼 공간 조회
  LitenSpace? getSpaceById(String spaceId) {
    return _findSpaceById(spaceId);
  }

  /// 오류 메시지 지우기
  void clearError() {
    _clearError();
  }

  /// 검색 쿼리 지우기
  void clearSearch() {
    _searchQuery = '';
    _applyFilterAndSort();
  }

  /// 필터 및 정렬 적용
  void _applyFilterAndSort() {
    // 검색 필터 적용
    if (_searchQuery.isEmpty) {
      _filteredSpaces = List.from(_spaces);
    } else {
      _filteredSpaces = _spaces.where((space) {
        return space.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (space.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // 정렬 적용
    _applySorting();
    
    notifyListeners();
  }

  /// 정렬 적용
  void _applySorting() {
    switch (_sortType) {
      case LitenSpaceSortType.title:
        _filteredSpaces.sort((a, b) => _sortDescending 
            ? b.title.compareTo(a.title)
            : a.title.compareTo(b.title));
        break;
      case LitenSpaceSortType.createdAt:
        _filteredSpaces.sort((a, b) => _sortDescending 
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt));
        break;
      case LitenSpaceSortType.updatedAt:
        _filteredSpaces.sort((a, b) => _sortDescending 
            ? b.updatedAt.compareTo(a.updatedAt)
            : a.updatedAt.compareTo(b.updatedAt));
        break;
      case LitenSpaceSortType.contentCount:
        _filteredSpaces.sort((a, b) => _sortDescending 
            ? b.totalContentCount.compareTo(a.totalContentCount)
            : a.totalContentCount.compareTo(b.totalContentCount));
        break;
    }
    
    notifyListeners();
  }

  /// ID로 리튼 공간 찾기
  LitenSpace? _findSpaceById(String spaceId) {
    try {
      return _spaces.firstWhere((space) => space.id == spaceId);
    } catch (e) {
      return null;
    }
  }

  /// 리스트에서 리튼 공간 업데이트
  void _updateSpaceInList(LitenSpace updatedSpace) {
    final index = _spaces.indexWhere((space) => space.id == updatedSpace.id);
    if (index != -1) {
      _spaces[index] = updatedSpace;
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 오류 메시지 설정
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// 오류 메시지 지우기
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// 리튼 공간 정렬 방식
enum LitenSpaceSortType {
  title('이름'),
  createdAt('생성일'),
  updatedAt('수정일'),
  contentCount('콘텐츠 수');

  const LitenSpaceSortType(this.displayName);
  final String displayName;
}
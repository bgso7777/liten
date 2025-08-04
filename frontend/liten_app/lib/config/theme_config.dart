import 'package:flutter/material.dart';

/// 5가지 테마 설정 (언어/지역별 자동 선택)
class ThemeConfig {
  
  /// 지원하는 테마 목록
  static const List<LitenTheme> availableThemes = [
    LitenTheme.classicBlue,
    LitenTheme.darkMode,
    LitenTheme.natureGreen,
    LitenTheme.sunsetOrange,
    LitenTheme.monochromeGrey,
  ];
  
  /// 언어/지역별 기본 테마 매핑 (31개 언어)
  static const Map<String, LitenTheme> localeThemeMap = {
    // 아시아
    'ko': LitenTheme.classicBlue,      // 한국 - 클래식 블루
    'ja': LitenTheme.classicBlue,      // 일본 - 클래식 블루
    'zh': LitenTheme.darkMode,         // 중국 간체 - 다크 모드
    'zh-TW': LitenTheme.darkMode,      // 중국 번체 - 다크 모드
    'hi': LitenTheme.sunsetOrange,     // 인도 - 선셋 오렌지
    'th': LitenTheme.natureGreen,      // 태국 - 네이처 그린
    'vi': LitenTheme.natureGreen,      // 베트남 - 네이처 그린
    'id': LitenTheme.natureGreen,      // 인도네시아 - 네이처 그린
    'ms': LitenTheme.natureGreen,      // 말레이시아 - 네이처 그린
    'tl': LitenTheme.sunsetOrange,     // 필리핀 - 선셋 오렌지
    'bn': LitenTheme.sunsetOrange,     // 방글라데시 - 선셋 오렌지
    'ur': LitenTheme.natureGreen,      // 우르두 - 네이처 그린
    'ta': LitenTheme.sunsetOrange,     // 타밀 - 선셋 오렌지
    
    // 유럽
    'en': LitenTheme.classicBlue,      // 영어 - 클래식 블루
    'es': LitenTheme.sunsetOrange,     // 스페인 - 선셋 오렌지
    'fr': LitenTheme.classicBlue,      // 프랑스 - 클래식 블루
    'de': LitenTheme.monochromeGrey,   // 독일 - 모노크롬 그레이
    'pt': LitenTheme.sunsetOrange,     // 포르투갈 - 선셋 오렌지
    'ru': LitenTheme.darkMode,         // 러시아 - 다크 모드
    'it': LitenTheme.classicBlue,      // 이탈리아 - 클래식 블루
    'nl': LitenTheme.monochromeGrey,   // 네덜란드 - 모노크롬 그레이
    'sv': LitenTheme.monochromeGrey,   // 스웨덴 - 모노크롬 그레이
    'no': LitenTheme.monochromeGrey,   // 노르웨이 - 모노크롬 그레이
    'da': LitenTheme.monochromeGrey,   // 덴마크 - 모노크롬 그레이
    'fi': LitenTheme.monochromeGrey,   // 핀란드 - 모노크롬 그레이
    'pl': LitenTheme.monochromeGrey,   // 폴란드 - 모노크롬 그레이
    'cs': LitenTheme.monochromeGrey,   // 체코 - 모노크롬 그레이
    'hu': LitenTheme.monochromeGrey,   // 헝가리 - 모노크롬 그레이
    'ro': LitenTheme.monochromeGrey,   // 루마니아 - 모노크롬 그레이
    'tr': LitenTheme.sunsetOrange,     // 터키 - 선셋 오렌지
    'uk': LitenTheme.darkMode,         // 우크라이나 - 다크 모드
    
    // 중동/아프리카
    'ar': LitenTheme.sunsetOrange,     // 아랍어 - 선셋 오렌지
    'he': LitenTheme.classicBlue,      // 히브리어 - 클래식 블루
    'fa': LitenTheme.sunsetOrange,     // 페르시아어 - 선셋 오렌지
    'sw': LitenTheme.natureGreen,      // 스와힐리어 - 네이처 그린
  };
  
  /// 언어 코드로 기본 테마 가져오기
  static LitenTheme getDefaultThemeForLocale(String languageCode) {
    return localeThemeMap[languageCode] ?? LitenTheme.classicBlue;
  }
  
  /// 테마 데이터 가져오기
  static ThemeData getThemeData(LitenTheme theme) {
    switch (theme) {
      case LitenTheme.classicBlue:
        return _buildClassicBlueTheme();
      case LitenTheme.darkMode:
        return _buildDarkModeTheme();
      case LitenTheme.natureGreen:
        return _buildNatureGreenTheme();
      case LitenTheme.sunsetOrange:
        return _buildSunsetOrangeTheme();
      case LitenTheme.monochromeGrey:
        return _buildMonochromeGreyTheme();
    }
  }
  
  /// 클래식 블루 테마
  static ThemeData _buildClassicBlueTheme() {
    const primaryColor = Color(0xFF1976D2);
    const surfaceColor = Color(0xFFF5F5F5);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  /// 다크 모드 테마
  static ThemeData _buildDarkModeTheme() {
    const primaryColor = Color(0xFF90CAF9);
    const surfaceColor = Color(0xFF121212);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 8,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  /// 네이처 그린 테마
  static ThemeData _buildNatureGreenTheme() {
    const primaryColor = Color(0xFF388E3C);
    const surfaceColor = Color(0xFFF1F8E9);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
  
  /// 선셋 오렌지 테마
  static ThemeData _buildSunsetOrangeTheme() {
    const primaryColor = Color(0xFFFF6F00);
    const surfaceColor = Color(0xFFFFF3E0);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardTheme(
        elevation: 6,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  /// 모노크롬 그레이 테마
  static ThemeData _buildMonochromeGreyTheme() {
    const primaryColor = Color(0xFF424242);
    const surfaceColor = Color(0xFFFAFAFA);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

/// 지원하는 테마 열거형
enum LitenTheme {
  classicBlue('클래식 블루', '전문적이고 신뢰감 있는 블루 테마'),
  darkMode('다크 모드', '눈에 편안한 어두운 테마'),
  natureGreen('네이처 그린', '자연스럽고 평온한 그린 테마'),
  sunsetOrange('선셋 오렌지', '따뜻하고 활기찬 오렌지 테마'),
  monochromeGrey('모노크롬 그레이', '깔끔하고 미니멀한 그레이 테마');
  
  const LitenTheme(this.displayName, this.description);
  
  final String displayName;
  final String description;
}
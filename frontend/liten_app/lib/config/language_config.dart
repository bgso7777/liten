import 'package:flutter/material.dart';

/// 지원되는 언어 정보
class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRTL = false,
  });
}

/// 언어 데이터 관리 클래스
class LanguageConfig {
  /// 지원하는 31개 언어 목록
  static const List<SupportedLanguage> supportedLanguages = [
    // 주요 언어 (기존 14개)
    SupportedLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    SupportedLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    SupportedLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    SupportedLanguage(code: 'zh', name: 'Chinese (Simplified)', nativeName: '简体中文', flag: '🇨🇳'),
    SupportedLanguage(code: 'zh-TW', name: 'Chinese (Traditional)', nativeName: '繁體中文', flag: '🇹🇼'),
    SupportedLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    SupportedLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    SupportedLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    SupportedLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
    SupportedLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    SupportedLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    SupportedLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', isRTL: true),
    SupportedLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    SupportedLanguage(code: 'th', name: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
    
    // 추가 17개 언어
    SupportedLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
    SupportedLanguage(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
    SupportedLanguage(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu', flag: '🇲🇾'),
    SupportedLanguage(code: 'tl', name: 'Filipino', nativeName: 'Filipino', flag: '🇵🇭'),
    SupportedLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
    SupportedLanguage(code: 'sv', name: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
    SupportedLanguage(code: 'no', name: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴'),
    SupportedLanguage(code: 'da', name: 'Danish', nativeName: 'Dansk', flag: '🇩🇰'),
    SupportedLanguage(code: 'fi', name: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮'),
    SupportedLanguage(code: 'pl', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
    SupportedLanguage(code: 'cs', name: 'Czech', nativeName: 'Čeština', flag: '🇨🇿'),
    SupportedLanguage(code: 'hu', name: 'Hungarian', nativeName: 'Magyar', flag: '🇭🇺'),
    SupportedLanguage(code: 'ro', name: 'Romanian', nativeName: 'Română', flag: '🇷🇴'),
    SupportedLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    SupportedLanguage(code: 'uk', name: 'Ukrainian', nativeName: 'Українська', flag: '🇺🇦'),
    SupportedLanguage(code: 'he', name: 'Hebrew', nativeName: 'עברית', flag: '🇮🇱', isRTL: true),
    SupportedLanguage(code: 'fa', name: 'Persian', nativeName: 'فارسی', flag: '🇮🇷', isRTL: true),
    SupportedLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🇧🇩'),
    SupportedLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇵🇰', isRTL: true),
    SupportedLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇱🇰'),
    SupportedLanguage(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili', flag: '🇰🇪'),
  ];

  /// 언어 코드로 언어 정보 조회
  static SupportedLanguage getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages.first, // 기본값: 한국어
    );
  }

  /// 언어의 표시명 (플래그 + 네이티브명)
  static String getDisplayName(String code) {
    final language = getLanguageByCode(code);
    return '${language.flag} ${language.nativeName}';
  }

  /// 언어별 기본 테마 매핑
  static Map<String, String> get languageThemeMapping => {
    // 아시아
    'ko': 'classicBlue',     // 한국 - 클래식 블루
    'ja': 'classicBlue',     // 일본 - 클래식 블루
    'zh': 'darkMode',        // 중국 - 다크 모드
    'zh-TW': 'darkMode',     // 대만 - 다크 모드
    'hi': 'sunsetOrange',    // 인도 - 선셋 오렌지
    'th': 'natureGreen',     // 태국 - 네이처 그린
    'vi': 'natureGreen',     // 베트남 - 네이처 그린
    'id': 'natureGreen',     // 인도네시아 - 네이처 그린
    'ms': 'natureGreen',     // 말레이시아 - 네이처 그린
    'tl': 'sunsetOrange',    // 필리핀 - 선셋 오렌지
    'bn': 'sunsetOrange',    // 방글라데시 - 선셋 오렌지
    'ur': 'natureGreen',     // 우르두 - 네이처 그린
    'ta': 'sunsetOrange',    // 타밀 - 선셋 오렌지
    
    // 유럽
    'en': 'classicBlue',     // 영어 - 클래식 블루
    'es': 'sunsetOrange',    // 스페인 - 선셋 오렌지
    'fr': 'classicBlue',     // 프랑스 - 클래식 블루
    'de': 'monochromeGrey',  // 독일 - 모노크롬 그레이
    'pt': 'sunsetOrange',    // 포르투갈 - 선셋 오렌지
    'ru': 'darkMode',        // 러시아 - 다크 모드
    'it': 'classicBlue',     // 이탈리아 - 클래식 블루
    'nl': 'monochromeGrey',  // 네덜란드 - 모노크롬 그레이
    'sv': 'monochromeGrey',  // 스웨덴 - 모노크롬 그레이
    'no': 'monochromeGrey',  // 노르웨이 - 모노크롬 그레이
    'da': 'monochromeGrey',  // 덴마크 - 모노크롬 그레이
    'fi': 'monochromeGrey',  // 핀란드 - 모노크롬 그레이
    'pl': 'monochromeGrey',  // 폴란드 - 모노크롬 그레이
    'cs': 'monochromeGrey',  // 체코 - 모노크롬 그레이
    'hu': 'monochromeGrey',  // 헝가리 - 모노크롬 그레이
    'ro': 'monochromeGrey',  // 루마니아 - 모노크롬 그레이
    'tr': 'sunsetOrange',    // 터키 - 선셋 오렌지
    'uk': 'darkMode',        // 우크라이나 - 다크 모드
    
    // 중동/아프리카
    'ar': 'sunsetOrange',    // 아랍어 - 선셋 오렌지
    'he': 'classicBlue',     // 히브리어 - 클래식 블루
    'fa': 'sunsetOrange',    // 페르시아어 - 선셋 오렌지
    'sw': 'natureGreen',     // 스와힐리어 - 네이처 그린
  };

  /// 언어별 기본 테마 가져오기
  static String getDefaultTheme(String languageCode) {
    return languageThemeMapping[languageCode] ?? 'classicBlue';
  }

  /// 지원되는 로케일 목록 (Flutter용)
  static List<Locale> get supportedLocales {
    return supportedLanguages.map((lang) {
      final parts = lang.code.split('-');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }
      return Locale(lang.code);
    }).toList();
  }

  /// 시스템 로케일에서 지원되는 언어 감지
  static String detectSupportedLanguage(Locale systemLocale) {
    final languageCode = systemLocale.languageCode;
    final countryCode = systemLocale.countryCode;
    
    // 정확한 매치 (언어+국가)
    if (countryCode != null) {
      final fullCode = '$languageCode-$countryCode';
      if (supportedLanguages.any((lang) => lang.code == fullCode)) {
        return fullCode;
      }
    }
    
    // 언어만 매치
    if (supportedLanguages.any((lang) => lang.code == languageCode)) {
      return languageCode;
    }
    
    // 기본값: 한국어
    return 'ko';
  }

  /// RTL 언어 확인
  static bool isRTL(String languageCode) {
    final language = getLanguageByCode(languageCode);
    return language.isRTL;
  }
}
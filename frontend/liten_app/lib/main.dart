import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'config/app_config.dart';
import 'config/theme_config.dart';
import 'providers/app_provider.dart';
import 'providers/liten_space_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const LitenApp());
}

class LitenApp extends StatelessWidget {
  const LitenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => LitenSpaceProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: AppConfig.isDebug,
            
            // 테마 설정
            theme: ThemeConfig.getThemeData(appProvider.currentTheme),
            
            // 다국어 설정
            locale: appProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              // 주요 언어 (기존 14개)
              Locale('ko', ''),       // 한국어
              Locale('en', ''),       // 영어
              Locale('ja', ''),       // 일본어
              Locale('zh', ''),       // 중국어 간체
              Locale('zh', 'TW'),     // 중국어 번체
              Locale('es', ''),       // 스페인어
              Locale('fr', ''),       // 프랑스어
              Locale('de', ''),       // 독일어
              Locale('ru', ''),       // 러시아어
              Locale('pt', ''),       // 포르투갈어
              Locale('it', ''),       // 이탈리아어
              Locale('ar', ''),       // 아랍어
              Locale('hi', ''),       // 힌디어
              Locale('th', ''),       // 태국어
              
              // 추가 17개 언어
              Locale('vi', ''),       // 베트남어
              Locale('id', ''),       // 인도네시아어
              Locale('ms', ''),       // 말레이어
              Locale('tl', ''),       // 필리피노어
              Locale('nl', ''),       // 네덜란드어
              Locale('sv', ''),       // 스웨덴어
              Locale('no', ''),       // 노르웨이어
              Locale('da', ''),       // 덴마크어
              Locale('fi', ''),       // 핀란드어
              Locale('pl', ''),       // 폴란드어
              Locale('cs', ''),       // 체코어
              Locale('hu', ''),       // 헝가리어
              Locale('ro', ''),       // 루마니아어
              Locale('tr', ''),       // 터키어
              Locale('uk', ''),       // 우크라이나어
              Locale('he', ''),       // 히브리어
              Locale('fa', ''),       // 페르시아어
              Locale('bn', ''),       // 벵골어
              Locale('ur', ''),       // 우르두어
              Locale('ta', ''),       // 타밀어
              Locale('sw', ''),       // 스와힐리어
            ],
            
            // 라우트 설정
            home: const SplashScreen(),
            
            // 전역 빌더 (오류 처리, 로딩 등)
            builder: (context, child) {
              return MediaQuery(
                // 텍스트 크기 고정 (사용자 설정 무시)
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
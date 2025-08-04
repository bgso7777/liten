import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/app_provider.dart';
import '../config/theme_config.dart';
import 'main_screen.dart';

/// 온보딩 화면 - 첫 실행 시 언어/테마 선택
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  // 지원하는 언어 목록
  final List<LocaleOption> _supportedLocales = [
    LocaleOption(locale: const Locale('ko'), name: '한국어', flag: '🇰🇷'),
    LocaleOption(locale: const Locale('en'), name: 'English', flag: '🇺🇸'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 진행 상태 표시
            _buildProgressIndicator(theme),
            
            // 페이지 콘텐츠
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(theme, l10n),
                  _buildLanguagePage(theme, l10n),
                  _buildThemePage(theme, l10n),
                  _buildCompletePage(theme, l10n),
                ],
              ),
            ),
            
            // 하단 네비게이션
            _buildBottomNavigation(theme, l10n),
          ],
        ),
      ),
    );
  }

  /// 진행 상태 표시
  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentPage 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 환영 페이지
  Widget _buildWelcomePage(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 앱 아이콘
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.mic_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 환영 메시지
          Text(
            l10n.appTitle,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            l10n.appDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // 기능 소개
          _buildFeatureList(theme, [
            FeatureItem(
              icon: Icons.record_voice_over,
              title: '음성 녹음',
              description: '고품질 음성 녹음 및 재생',
            ),
            FeatureItem(
              icon: Icons.edit_note,
              title: '텍스트 작성',
              description: '실시간 편집 및 동기화',
            ),
            FeatureItem(
              icon: Icons.draw,
              title: '필기 및 스케치',
              description: '자유로운 그림 및 필기',
            ),
          ]),
        ],
      ),
    );
  }

  /// 언어 선택 페이지
  Widget _buildLanguagePage(ThemeData theme, AppLocalizations l10n) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              Text(
                '언어 선택',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '사용할 언어를 선택해주세요',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: ListView.builder(
                  itemCount: _supportedLocales.length,
                  itemBuilder: (context, index) {
                    final localeOption = _supportedLocales[index];
                    final isSelected = appProvider.currentLocale == localeOption.locale;
                    
                    return Card(
                      elevation: isSelected ? 4 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Text(
                          localeOption.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          localeOption.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected 
                            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                            : const Icon(Icons.radio_button_unchecked),
                        onTap: () {
                          appProvider.changeLocale(localeOption.locale);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 테마 선택 페이지
  Widget _buildThemePage(ThemeData theme, AppLocalizations l10n) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              Text(
                '테마 선택',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '원하는 테마를 선택해주세요',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: ThemeConfig.availableThemes.length,
                  itemBuilder: (context, index) {
                    final themeOption = ThemeConfig.availableThemes[index];
                    final isSelected = appProvider.currentTheme == themeOption;
                    final themeData = ThemeConfig.getThemeData(themeOption);
                    
                    return GestureDetector(
                      onTap: () {
                        appProvider.changeTheme(themeOption);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.surface,
                          border: Border.all(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.outline.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: themeData.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              themeOption.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 완료 페이지
  Widget _buildCompletePage(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '설정 완료!',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '이제 리튼을 사용할 준비가 되었습니다.\n첫 번째 리튼 공간을 만들어보세요!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 하단 네비게이션
  Widget _buildBottomNavigation(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 버튼
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('이전'),
            )
          else
            const SizedBox(width: 80),
          
          // 다음/완료 버튼
          ElevatedButton(
            onPressed: _isCompleting ? null : _handleNextButton,
            child: _isCompleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_currentPage < 3 ? '다음' : '시작하기'),
          ),
        ],
      ),
    );
  }

  /// 기능 목록 위젯
  Widget _buildFeatureList(ThemeData theme, List<FeatureItem> features) {
    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature.icon,
                  color: theme.colorScheme.primary,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      feature.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 다음 버튼 처리
  void _handleNextButton() async {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  /// 온보딩 완료
  Future<void> _completeOnboarding() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.completeFirstRun();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return const MainScreen();
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCompleting = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// 언어 옵션
class LocaleOption {
  final Locale locale;
  final String name;
  final String flag;

  const LocaleOption({
    required this.locale,
    required this.name,
    required this.flag,
  });
}

/// 기능 아이템
class FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
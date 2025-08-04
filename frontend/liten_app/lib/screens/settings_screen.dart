import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/app_provider.dart';
import '../config/app_config.dart';
import '../config/theme_config.dart';

/// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 앱 설정 섹션
          _buildSectionHeader(theme, '앱 설정'),
          _buildThemeSettings(theme, l10n),
          _buildLanguageSettings(theme, l10n),
          
          const SizedBox(height: 24),
          
          // 저장소 섹션
          _buildSectionHeader(theme, l10n.settings_storage),
          _buildStorageSettings(theme, l10n),
          
          const SizedBox(height: 24),
          
          // 앱 정보 섹션
          _buildSectionHeader(theme, l10n.settings_about),
          _buildAboutSettings(theme, l10n),
        ],
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 테마 설정
  Widget _buildThemeSettings(ThemeData theme, AppLocalizations l10n) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(l10n.settings_theme),
                subtitle: Text(appProvider.currentTheme.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(appProvider),
              ),
              
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('다크 모드'),
                trailing: Switch(
                  value: appProvider.isDarkMode,
                  onChanged: (value) {
                    appProvider.toggleDarkMode();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 언어 설정
  Widget _buildLanguageSettings(ThemeData theme, AppLocalizations l10n) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settings_language),
            subtitle: Text(_getLanguageName(appProvider.currentLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(appProvider),
          ),
        );
      },
    );
  }

  /// 저장소 설정
  Widget _buildStorageSettings(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('사용된 저장 공간'),
            subtitle: const Text('계산 중...'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStorageInfo(),
          ),
          
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('임시 파일 정리'),
            subtitle: const Text('불필요한 임시 파일을 삭제합니다'),
            onTap: () => _cleanupTempFiles(),
          ),
        ],
      ),
    );
  }

  /// 앱 정보 설정
  Widget _buildAboutSettings(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 버전'),
            subtitle: Text('v${AppConfig.appVersion}'),
          ),
          
          ListTile(
            leading: const Icon(Icons.verified),
            title: const Text('버전 유형'),
            subtitle: Text(AppConfig.currentMode == AppMode.free 
                ? l10n.version_free 
                : l10n.version_standard),
          ),
          
          if (AppConfig.isDebug)
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('디버그 모드'),
              subtitle: const Text('개발자 전용 모드'),
            ),
          
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('오픈소스 라이선스'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenses(),
          ),
        ],
      ),
    );
  }

  /// 테마 선택 다이얼로그
  void _showThemeDialog(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ThemeConfig.availableThemes.length,
            itemBuilder: (context, index) {
              final theme = ThemeConfig.availableThemes[index];
              final isSelected = appProvider.currentTheme == theme;
              
              return RadioListTile<LitenTheme>(
                title: Text(theme.displayName),
                subtitle: Text(theme.description),
                value: theme,
                groupValue: appProvider.currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    appProvider.changeTheme(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 언어 선택 다이얼로그
  void _showLanguageDialog(AppProvider appProvider) {
    final languages = [
      {'locale': const Locale('ko'), 'name': '한국어', 'flag': '🇰🇷'},
      {'locale': const Locale('en'), 'name': 'English', 'flag': '🇺🇸'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('언어 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              final locale = language['locale'] as Locale;
              final isSelected = appProvider.currentLocale == locale;
              
              return RadioListTile<Locale>(
                title: Row(
                  children: [
                    Text(language['flag'] as String),
                    const SizedBox(width: 8),
                    Text(language['name'] as String),
                  ],
                ),
                value: locale,
                groupValue: appProvider.currentLocale,
                onChanged: (value) {
                  if (value != null) {
                    appProvider.changeLocale(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 저장소 정보 표시
  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장소 정보'),
        content: const Text('저장소 정보를 계산하는 중...\n\n(추후 구현 예정)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 임시 파일 정리
  void _cleanupTempFiles() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('임시 파일을 정리하는 중...'),
          ],
        ),
      ),
    );

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.fileService.cleanupTempFiles();
      
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('임시 파일 정리가 완료되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('임시 파일 정리 중 오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 오픈소스 라이선스 표시
  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: AppConfig.appVersion,
    );
  }

  /// 언어 이름 가져오기
  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}
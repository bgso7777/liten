import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../config/language_config.dart';
import '../providers/app_provider.dart';

/// 언어 선택 화면
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _selectedLanguage = appProvider.currentLocale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: _buildAppBar(theme, l10n),
      body: Column(
        children: [
          _buildLanguageStatus(theme),
          _buildSearchBar(theme, l10n),
          Expanded(child: _buildLanguageList(theme, l10n)),
        ],
      ),
    );
  }

  /// 언어 지원 상태 표시
  Widget _buildLanguageStatus(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LanguageConfig.getLanguageSupportStatus(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 앱바 구성
  PreferredSizeWidget _buildAppBar(ThemeData theme, AppLocalizations l10n) {
    return AppBar(
      title: const Text('언어 선택'),
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      actions: [
        TextButton(
          onPressed: _selectedLanguage != null ? _saveLanguage : null,
          child: Text(
            '완료',
            style: TextStyle(
              color: _selectedLanguage != null 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 검색바 구성
  Widget _buildSearchBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '언어 검색...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  /// 언어 목록 구성
  Widget _buildLanguageList(ThemeData theme, AppLocalizations l10n) {
    final filteredLanguages = LanguageConfig.supportedLanguages.where((language) {
      if (_searchQuery.isEmpty) return true;
      return language.name.toLowerCase().contains(_searchQuery) ||
             language.nativeName.toLowerCase().contains(_searchQuery) ||
             language.code.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredLanguages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredLanguages.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final language = filteredLanguages[index];
        return _buildLanguageItem(theme, language);
      },
    );
  }

  /// 언어 항목 구성
  Widget _buildLanguageItem(ThemeData theme, SupportedLanguage language) {
    final isSelected = _selectedLanguage == language.code;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            language.flag,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        language.nativeName,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        language.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language.code;
        });
      },
    );
  }

  /// 언어 저장
  void _saveLanguage() async {
    if (_selectedLanguage == null) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final parts = _selectedLanguage!.split('-');
    final locale = parts.length == 2 
        ? Locale(parts[0], parts[1])
        : Locale(_selectedLanguage!);

    await appProvider.changeLocale(locale);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('언어가 변경되었습니다: ${LanguageConfig.getDisplayName(_selectedLanguage!)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
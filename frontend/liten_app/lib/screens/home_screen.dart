import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/app_provider.dart';
import '../providers/liten_space_provider.dart';
import '../config/app_config.dart';
import '../widgets/liten_space_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/create_space_dialog.dart';

/// 홈 화면 - 리튼 공간 목록
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  /// 리튼 공간 목록 로드
  Future<void> _loadSpaces() async {
    final spaceProvider = Provider.of<LitenSpaceProvider>(context, listen: false);
    await spaceProvider.loadSpaces();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme, l10n),
          _buildSliverBody(theme, l10n),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme, l10n),
    );
  }

  /// SliverAppBar 구성
  Widget _buildSliverAppBar(ThemeData theme, AppLocalizations l10n) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      title: _isSearching ? _buildSearchField(theme, l10n) : Text(
        AppConfig.appName,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
            tooltip: '검색',
          ),
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            },
            tooltip: '검색 취소',
          ),
      ],
    );
  }

  /// 검색 필드 구성
  Widget _buildSearchField(ThemeData theme, AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '리튼 공간 검색...',
        border: InputBorder.none,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        // TODO: 검색 기능 구현
      },
    );
  }

  /// SliverBody 구성
  Widget _buildSliverBody(ThemeData theme, AppLocalizations l10n) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: Consumer<LitenSpaceProvider>(
        builder: (context, spaceProvider, child) {
          if (spaceProvider.isLoading) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (spaceProvider.errorMessage != null) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      spaceProvider.errorMessage ?? '알 수 없는 오류가 발생했습니다',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSpaces,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (spaceProvider.spaces.isEmpty) {
            return SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.folder_outlined,
                title: '아직 리튼 공간이 없어요',
                subtitle: '첫 번째 리튼 공간을 만들어보세요!\n음성, 텍스트, 그림을 함께 관리할 수 있어요.',
                actionLabel: '새 리튼 공간 만들기',
                onActionPressed: () => _showCreateSpaceDialog(context),
              ),
            );
          }

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final space = spaceProvider.spaces[index];
                return LitenSpaceCard(
                  space: space,
                  onTap: () {
                    // TODO: 리튼 공간 상세 화면으로 이동
                  },
                );
              },
              childCount: spaceProvider.spaces.length,
            ),
          );
        },
      ),
    );
  }

  /// FloatingActionButton 구성
  Widget _buildFloatingActionButton(ThemeData theme, AppLocalizations l10n) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateSpaceDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('새 리튼 공간'),
      tooltip: '새 리튼 공간 만들기',
    );
  }

  /// 리튼 공간 생성 다이얼로그 표시
  void _showCreateSpaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateSpaceDialog(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
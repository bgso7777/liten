import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/app_provider.dart';
import '../config/app_config.dart';

/// 쓰기 화면 - 텍스트 작성 및 편집
class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  
  bool _hasChanges = false;
  bool _isFullScreen = false;
  
  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (!_isFullScreen) _buildSliverAppBar(theme, l10n),
          _buildSliverBody(theme, l10n),
        ],
      ),
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
      title: Text(
        '쓰기',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
      actions: [
        if (_hasChanges)
          TextButton(
            onPressed: _save,
            child: Text(
              '저장',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        IconButton(
          icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          onPressed: () => setState(() => _isFullScreen = !_isFullScreen),
          tooltip: _isFullScreen ? '전체화면 나가기' : '전체화면',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('내보내기'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'template',
              child: ListTile(
                leading: Icon(Icons.description),
                title: Text('템플릿'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'format',
              child: ListTile(
                leading: Icon(Icons.format_paint),
                title: Text('서식'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// SliverBody 구성
  Widget _buildSliverBody(ThemeData theme, AppLocalizations l10n) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 제목 입력 필드
            _buildTitleField(theme),
            const SizedBox(height: 16),
            
            // 구분선
            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            
            // 내용 입력 필드
            Expanded(child: _buildContentField(theme)),
          ],
        ),
      ),
    );
  }

  /// 제목 입력 필드
  Widget _buildTitleField(ThemeData theme) {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: '제목을 입력하세요...',
        border: InputBorder.none,
        hintStyle: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontWeight: FontWeight.normal,
        ),
      ),
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  /// 내용 입력 필드
  Widget _buildContentField(ThemeData theme) {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: '내용을 입력하세요...\n\n마크다운 문법을 지원합니다:\n- **굵게**\n- *기울임*\n- # 제목\n- - 목록',
        border: InputBorder.none,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          height: 1.5,
        ),
      ),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
    );
  }

  /// 메뉴 액션 처리
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _export();
        break;
      case 'template':
        _showTemplateDialog();
        break;
      case 'format':
        _showFormatDialog();
        break;
    }
  }

  /// 저장
  void _save() {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목 또는 내용을 입력해주세요')),
      );
      return;
    }

    // TODO: 실제 저장 로직 구현
    setState(() {
      _hasChanges = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장되었습니다')),
    );

    if (AppConfig.enableDetailedLogging) {
      print('텍스트 저장: ${_titleController.text}');
    }
  }

  /// 내보내기
  void _export() {
    // TODO: 실제 내보내기 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('내보내기 기능은 준비 중입니다')),
    );
  }

  /// 템플릿 다이얼로그 표시
  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('템플릿 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('회의록'),
              subtitle: const Text('회의 내용을 정리하는 템플릿'),
              onTap: () {
                _applyTemplate('meeting');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('일기'),
              subtitle: const Text('일상을 기록하는 템플릿'),
              onTap: () {
                _applyTemplate('diary');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('아이디어'),
              subtitle: const Text('아이디어를 정리하는 템플릿'),
              onTap: () {
                _applyTemplate('idea');
                Navigator.pop(context);
              },
            ),
          ],
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

  /// 서식 다이얼로그 표시
  void _showFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('서식 옵션'),
        content: const Text('서식 기능은 준비 중입니다.\n현재 마크다운 문법을 지원합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 템플릿 적용
  void _applyTemplate(String templateType) {
    String title = '';
    String content = '';

    switch (templateType) {
      case 'meeting':
        title = '회의록 - ${DateTime.now().toString().substring(0, 10)}';
        content = '''# 회의 정보
- **일시**: ${DateTime.now().toString().substring(0, 16)}
- **참석자**: 
- **장소**: 

# 안건
1. 

# 논의 내용


# 결정 사항


# 액션 아이템
- [ ] 
''';
        break;
      case 'diary':
        title = '일기 - ${DateTime.now().toString().substring(0, 10)}';
        content = '''# 오늘의 기분
😊

# 오늘 있었던 일


# 감사한 일


# 내일 할 일
- [ ] 
''';
        break;
      case 'idea':
        title = '아이디어 - ${DateTime.now().toString().substring(0, 10)}';
        content = '''# 아이디어 제목


# 핵심 내용


# 장점
- 

# 단점
- 

# 실행 방안
1. 
''';
        break;
    }

    setState(() {
      _titleController.text = title;
      _contentController.text = content;
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }
}
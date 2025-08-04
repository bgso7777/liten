import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/app_provider.dart';
import '../config/app_config.dart';

/// 듣기 화면 - 음성 녹음 및 재생
class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _recordingDuration = Duration.zero;
  
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
        '듣기',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            // TODO: 녹음 기록 화면으로 이동
          },
          tooltip: '녹음 기록',
        ),
      ],
    );
  }

  /// SliverBody 구성
  Widget _buildSliverBody(ThemeData theme, AppLocalizations l10n) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 녹음 상태 표시
            _buildRecordingStatus(theme),
            const SizedBox(height: 48),
            
            // 메인 녹음 버튼
            _buildRecordingButton(theme),
            const SizedBox(height: 32),
            
            // 녹음 시간 표시
            _buildDurationDisplay(theme),
            const SizedBox(height: 48),
            
            // 컨트롤 버튼들
            _buildControlButtons(theme),
            const SizedBox(height: 32),
            
            // 안내 텍스트
            _buildHelpText(theme),
          ],
        ),
      ),
    );
  }

  /// 녹음 상태 표시
  Widget _buildRecordingStatus(ThemeData theme) {
    if (!_isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '준비됨',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '녹음 중...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 메인 녹음 버튼
  Widget _buildRecordingButton(ThemeData theme) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? theme.colorScheme.error : theme.colorScheme.primary)
                  .withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          size: 48,
          color: _isRecording ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// 녹음 시간 표시
  Widget _buildDurationDisplay(ThemeData theme) {
    return Text(
      _formatDuration(_recordingDuration),
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );
  }

  /// 컨트롤 버튼들
  Widget _buildControlButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 재생 버튼
        IconButton.filled(
          onPressed: _isRecording ? null : _togglePlayback,
          iconSize: 32,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          tooltip: _isPlaying ? '일시정지' : '재생',
        ),
        
        // 정지 버튼
        IconButton.filled(
          onPressed: (_isRecording || _isPlaying) ? _stop : null,
          iconSize: 32,
          icon: const Icon(Icons.stop),
          tooltip: '정지',
        ),
        
        // 저장 버튼
        IconButton.filled(
          onPressed: _recordingDuration > Duration.zero ? _save : null,
          iconSize: 32,
          icon: const Icon(Icons.save),
          tooltip: '저장',
        ),
      ],
    );
  }

  /// 안내 텍스트
  Widget _buildHelpText(ThemeData theme) {
    return Text(
      '마이크 버튼을 눌러 녹음을 시작하세요.\n녹음된 내용은 현재 선택된 리튼 공간에 저장됩니다.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  /// 녹음 토글
  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _startRecording();
      } else {
        _stopRecording();
      }
    });
  }

  /// 재생 토글
  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startPlayback();
      } else {
        _pausePlayback();
      }
    });
  }

  /// 정지
  void _stop() {
    setState(() {
      _isRecording = false;
      _isPlaying = false;
    });
    // TODO: 실제 정지 로직 구현
  }

  /// 저장
  void _save() {
    // TODO: 실제 저장 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('녹음이 저장되었습니다')),
    );
  }

  /// 녹음 시작
  void _startRecording() {
    // TODO: 실제 녹음 시작 로직 구현
    if (AppConfig.enableDetailedLogging) {
      print('녹음 시작');
    }
  }

  /// 녹음 중지
  void _stopRecording() {
    // TODO: 실제 녹음 중지 로직 구현
    if (AppConfig.enableDetailedLogging) {
      print('녹음 중지');
    }
  }

  /// 재생 시작
  void _startPlayback() {
    // TODO: 실제 재생 시작 로직 구현
    if (AppConfig.enableDetailedLogging) {
      print('재생 시작');
    }
  }

  /// 재생 일시정지
  void _pausePlayback() {
    // TODO: 실제 재생 일시정지 로직 구현
    if (AppConfig.enableDetailedLogging) {
      print('재생 일시정지');
    }
  }

  /// 시간 포맷팅
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
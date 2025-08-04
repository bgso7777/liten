import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/liten_space.dart';

/// 리튼 공간 카드 위젯
class LitenSpaceCard extends StatelessWidget {
  final LitenSpace space;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const LitenSpaceCard({
    super.key,
    required this.space,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM/dd HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (제목과 메뉴)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      space.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            const Text('편집'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            const Icon(Icons.copy),
                            const SizedBox(width: 8),
                            const Text('복제'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: theme.colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // 설명 (있는 경우)
              if (space.description != null && space.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  space.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 16),
              
              // 콘텐츠 통계
              Row(
                children: [
                  _buildStatChip(
                    theme,
                    Icons.mic,
                    space.audioCount.toString(),
                    '오디오',
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    theme,
                    Icons.text_fields,
                    space.textCount.toString(),
                    '텍스트',
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    theme,
                    Icons.draw,
                    space.drawingCount.toString(),
                    '그림',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 하단 정보 (날짜, 동기화 상태)
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '수정: ${dateFormat.format(space.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 동기화 상태 (2차 버전용)
                  if (space.isSynced)
                    Icon(
                      Icons.cloud_done,
                      size: 16,
                      color: theme.colorScheme.primary,
                    )
                  else
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 통계 칩 생성
  Widget _buildStatChip(ThemeData theme, IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 메뉴 액션 처리
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'duplicate':
        onDuplicate?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}
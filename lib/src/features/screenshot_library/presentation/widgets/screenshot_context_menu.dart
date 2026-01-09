import 'package:flutter/material.dart';

class ScreenshotContextMenu extends StatelessWidget {
  final Widget child;
  final VoidCallback? onMoveToTrash; // 移入回收站 (图库用)
  final VoidCallback? onRestore; // 恢复 (回收站用)
  final VoidCallback? onPermanentlyDelete; // 彻底删除 (回收站用)
  final VoidCallback? onOpen; // 打开/查看 (通用)
  final VoidCallback? onCopyImg; // 复制图片文件
  final VoidCallback? onToggleFavorite; // 切换收藏状态
  final bool? isFavorite; // 当前是否已收藏

  const ScreenshotContextMenu({
    super.key,
    required this.child,
    this.onMoveToTrash,
    this.onRestore,
    this.onPermanentlyDelete,
    this.onOpen,
    this.onCopyImg,
    this.onToggleFavorite,
    this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 监听右键按下 (桌面端习惯)
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    final colorScheme = Theme.of(context).colorScheme;

    // 构建菜单项列表
    final List<PopupMenuEntry<String>> items = [];

    if (onOpen != null) {
      items.add(
        _buildMenuItem(
          value: 'open',
          icon: Icons.visibility_outlined,
          label: '默认程序查看',
          color: colorScheme.onSurface,
        ),
      );
    }

    if (onCopyImg != null) {
      items.add(
        _buildMenuItem(
          value: 'copy_img',
          icon: Icons.copy,
          label: '复制图片文件',
          color: colorScheme.onSurface,
        ),
      );
    }

    if (onToggleFavorite != null) {
      items.add(
        _buildMenuItem(
          value: 'toggle_favorite',
          icon: isFavorite == true ? Icons.star : Icons.star_border,
          label: isFavorite == true ? '取消收藏' : '收藏',
          color: isFavorite == true ? Colors.amber : colorScheme.onSurface,
        ),
      );
    }

    if (onMoveToTrash != null) {
      items.add(
        _buildMenuItem(
          value: 'trash',
          icon: Icons.delete_outline,
          label: '移至回收站',
          color: colorScheme.error,
        ),
      );
    }

    if (onRestore != null) {
      items.add(
        _buildMenuItem(
          value: 'restore',
          icon: Icons.restore_from_trash,
          label: '恢复',
          color: colorScheme.primary,
        ),
      );
    }

    if (onPermanentlyDelete != null) {
      items.add(
        _buildMenuItem(
          value: 'delete_forever',
          icon: Icons.delete_forever,
          label: '彻底删除',
          color: colorScheme.error,
        ),
      );
    }

    // 如果没有可用菜单项，直接返回
    if (items.isEmpty) return;

    // 显示菜单
    final String? selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: items,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    // 处理点击结果
    if (selected == null) return;

    switch (selected) {
      case 'open':
        onOpen?.call();
        break;
      case 'copy_img':
        onCopyImg?.call();
        break;
      case 'toggle_favorite':
        onToggleFavorite?.call();
        break;
      case 'trash':
        onMoveToTrash?.call();
        break;
      case 'restore':
        onRestore?.call();
        break;
      case 'delete_forever':
        onPermanentlyDelete?.call();
        break;
    }
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

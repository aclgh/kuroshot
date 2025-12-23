import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/screenshot.dart';
import '../controllers/library_controller.dart';
import '../screenshot_preview_page.dart';

class ScreenshotCard extends StatefulWidget {
  final Screenshot screenshot;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
  });

  @override
  State<ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends State<ScreenshotCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = widget.isSelected;
    final isSelectionMode = widget.isSelectionMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      // 使用 AnimatedContainer 实现平滑的缩放和阴影过渡
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack, // 缩放使用回弹曲线
        transform: Matrix4.identity()
          ..scaleByDouble(
            _isHovered && !isSelectionMode ? 1.05 : 1.0,
            _isHovered && !isSelectionMode ? 1.05 : 1.0,
            _isHovered && !isSelectionMode ? 1.05 : 1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut, // 阴影使用普通曲线，防止 blurRadius < 0 导致崩溃
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered && !isSelectionMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片区域
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : (_isHovered
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  )),
                      width: isSelected || _isHovered ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(widget.screenshot.path),
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                      // 选中遮罩
                      if (isSelected)
                        Container(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          // child: Center(
                          //   child: Container(
                          //     padding: const EdgeInsets.all(8),
                          //     decoration: BoxDecoration(
                          //       color: colorScheme.primary,
                          //       shape: BoxShape.circle,
                          //     ),
                          //     child: Icon(
                          //       Icons.check,
                          //       color: colorScheme.onPrimary,
                          //       size: 24,
                          //     ),
                          //   ),
                          // ),
                        ),
                      // Hover 遮罩 (非选择模式)
                      if (!isSelectionMode)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isHovered ? 0.0 : 0.0,
                          child: Container(color: Colors.black),
                        ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (isSelectionMode) {
                              widget.onToggleSelection?.call();
                            } else {
                              final controller = context
                                  .read<LibraryController>();
                              final index = controller.screenshots.indexOf(
                                widget.screenshot,
                              );
                              if (index != -1) {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    barrierColor: Colors.black.withValues(
                                      alpha: 0.9,
                                    ),
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: ScreenshotPreviewPage(
                                              initialIndex: index,
                                            ),
                                          );
                                        },
                                  ),
                                );
                              }
                            }
                          },
                          onLongPress: () {
                            if (!isSelectionMode) {
                              // 长按进入选择模式并选中当前项
                              context
                                  .read<LibraryController>()
                                  .toggleSelectionMode();
                              context.read<LibraryController>().toggleSelection(
                                widget.screenshot.id,
                              );
                            }
                          },
                          hoverColor: Colors.transparent,
                        ),
                      ),
                      // 选择模式下的复选框
                      if (isSelectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    )
                                  : const SizedBox(width: 16, height: 16),
                            ),
                          ),
                        ),
                      // 收藏标记
                      if (widget.screenshot.isFavorite)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 标题区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _isHovered || isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: _isHovered || isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                  child: Text(
                    widget.screenshot.timestamp.toLocal().toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

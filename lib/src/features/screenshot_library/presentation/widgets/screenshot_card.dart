import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/screenshot.dart';
import '../controllers/library_controller.dart';
import '../screenshot_preview_page.dart';

class ScreenshotCard extends StatefulWidget {
  final Screenshot screenshot;

  const ScreenshotCard({super.key, required this.screenshot});

  @override
  State<ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends State<ScreenshotCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      // 使用 AnimatedContainer 实现平滑的缩放和阴影过渡
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack, // 缩放使用回弹曲线
        transform: Matrix4.identity()
          ..scaleByDouble(
            _isHovered ? 1.05 : 1.0,
            _isHovered ? 1.05 : 1.0,
            _isHovered ? 1.05 : 1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut, // 阴影使用普通曲线，防止 blurRadius < 0 导致崩溃
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
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
                      color: _isHovered
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: _isHovered ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(widget.screenshot.path),
                        fit: BoxFit.cover,
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
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isHovered ? 0.0 : 0.0,
                        child: Container(color: Colors.black),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
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
                                      (context, animation, secondaryAnimation) {
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
                          },
                          hoverColor: Colors.transparent, // 禁用默认的 hover 灰色背景
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
                    color: _isHovered
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
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

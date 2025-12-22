import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/library_controller.dart';
import '../domain/screenshot.dart';

class ScreenshotPreviewPage extends StatefulWidget {
  final int initialIndex;

  const ScreenshotPreviewPage({super.key, required this.initialIndex});

  @override
  State<ScreenshotPreviewPage> createState() => _ScreenshotPreviewPageState();
}

class _ScreenshotPreviewPageState extends State<ScreenshotPreviewPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousPage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextPage();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    final count = context.read<LibraryController>().screenshots.length;
    if (_currentIndex < count - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showDetails(Screenshot screenshot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DetailsSheet(screenshot: screenshot),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<LibraryController>(
        builder: (context, controller, child) {
          final screenshots = controller.screenshots;
          if (screenshots.isEmpty) return const SizedBox();

          return KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image Viewer
                GestureDetector(
                  onTap: () => setState(() => _showControls = !_showControls),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: screenshots.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.file(
                            File(screenshots[index].path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Top Bar (Back button)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: _showControls ? 0 : -80,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _showDetails(screenshots[_currentIndex]),
                            tooltip: "详情",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Navigation Buttons (Left/Right)
                if (_showControls && _currentIndex > 0)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filledTonal(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.chevron_left, size: 32),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                if (_showControls && _currentIndex < screenshots.length - 1)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filledTonal(
                        onPressed: _nextPage,
                        icon: const Icon(Icons.chevron_right, size: 32),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final Screenshot screenshot;

  const _DetailsSheet({required this.screenshot});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "图片详情",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildDetailItem(
                  context,
                  "文件名",
                  screenshot.path.split(Platform.pathSeparator).last,
                ),
                _buildDetailItem(context, "路径", screenshot.path),
                _buildDetailItem(
                  context,
                  "时间",
                  screenshot.timestamp.toString(),
                ),
                _buildDetailItem(
                  context,
                  "大小",
                  _formatSize(screenshot.filesize),
                ),
                _buildDetailItem(
                  context,
                  "尺寸",
                  "${screenshot.width} x ${screenshot.height}",
                ),
                _buildDetailItem(context, "来源", screenshot.source),
                if (screenshot.appName != null)
                  _buildDetailItem(context, "应用", screenshot.appName!),
                if (screenshot.windowTitle != null)
                  _buildDetailItem(context, "窗口", screenshot.windowTitle!),
                if (screenshot.tags.isNotEmpty)
                  _buildDetailItem(context, "标签", screenshot.tags.join(", ")),
                if (screenshot.ocrText != null &&
                    screenshot.ocrText!.isNotEmpty)
                  _buildDetailItem(context, "OCR文字", screenshot.ocrText!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

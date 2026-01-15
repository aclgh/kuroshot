import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:pasteboard/pasteboard.dart';
import 'package:kuroshot/utils/logger.dart';

import 'controllers/category_controller.dart';
import '../../screenshot_library/presentation/widgets/screenshot_card.dart';
import '../../screenshot_library/presentation/widgets/screenshot_context_menu.dart';
import '../../screenshot_library/presentation/widgets/page_input.dart';
import '../../../shared/widgets/app_snack_bar.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  void initState() {
    super.initState();
    // 添加全局键盘监听
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    // 移除全局键盘监听
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final controller = context.read<CategoryController>();

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // 左键：上一页
        if (controller.page > 1) {
          controller.updatePage(controller.page - 1);
          return true;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // 右键：下一页
        if (controller.page < controller.allPages) {
          controller.updatePage(controller.page + 1);
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 使用 Consumer 监听 CategoryController 的变化
      body: Consumer<CategoryController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              // 顶部工具栏
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildToolbar(context, controller, colorScheme),
                ),
              ),

              // 根据选中的分类显示对应的筛选器
              if (controller.selectedCategory == '文件大小')
                SliverToBoxAdapter(
                  child: _buildFileSizeFilter(context, controller),
                ),
              if (controller.selectedCategory == '时间')
                SliverToBoxAdapter(
                  child: _buildDateFilter(context, controller),
                ),

              // 截图展示
              if (controller.screenshots.isEmpty && !controller.isLoading)
                SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: Text(
                      "该分类下暂无截图",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200, // 每个卡片最大宽度
                          childAspectRatio: 1.2, // 宽高比
                          crossAxisSpacing: 16, // 水平间距
                          mainAxisSpacing: 24, // 垂直间距
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final screenshot = controller.screenshots[index];
                      return ScreenshotContextMenu(
                        isFavorite: screenshot.isFavorite,
                        onToggleFavorite: () async {
                          final wasFavorite = screenshot.isFavorite;
                          final success = await controller.toggleFavorite(
                            screenshot.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar(
                                context,
                                message: success
                                    ? (wasFavorite ? '已取消收藏' : '已收藏')
                                    : controller.lastError ?? '操作失败',
                              ),
                            );
                            if (success) {
                              controller.clearError();
                            }
                          }
                        },
                        onMoveToTrash: () async {
                          controller.selectedIds.add(screenshot.id);
                          final success = await controller.deleteSelected();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar(
                                context,
                                message: success
                                    ? '已移至回收站'
                                    : controller.lastError ?? '删除失败',
                              ),
                            );
                            if (success) {
                              controller.clearError();
                            }
                          }
                        },
                        onOpen: () {
                          OpenFile.open(screenshot.path);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar(context, message: '已使用默认程序打开图片'),
                            );
                          }
                        },
                        onCopyImg: () async {
                          try {
                            final file = File(screenshot.path);
                            if (await file.exists()) {
                              final bytes = await file.readAsBytes();
                              await Pasteboard.writeImage(bytes);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackBar(context, message: '图片已复制到剪切板'),
                              );
                            }
                          } catch (e) {
                            logger.e("复制图片失败: $e");
                          }
                        },
                        child: ScreenshotCard(
                          screenshot: screenshot,
                          isSelectionMode: controller.isSelectionMode,
                          isSelected: controller.selectedIds.contains(
                            screenshot.id,
                          ),
                          onToggleSelection: () =>
                              controller.toggleSelection(screenshot.id),
                        ),
                      );
                    }, childCount: controller.screenshots.length),
                  ),
                ),

              // 分页控制
              if (controller.allPages > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: controller.page > 1
                              ? () => controller.updatePage(controller.page - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: "上一页",
                        ),
                        const SizedBox(width: 16),
                        PageInput(
                          currentPage: controller.page,
                          totalPages: controller.allPages,
                          onPageChanged: (page) => controller.updatePage(page),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: controller.page < controller.allPages
                              ? () => controller.updatePage(controller.page + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: "下一页",
                        ),
                      ],
                    ),
                  ),
                ),

              // 底部留白
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    CategoryController controller,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Text(
          "分类",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: colorScheme.onSurface,
          ),
        ),
        if (controller.isLoading) ...[
          const SizedBox(width: 16),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
        const Spacer(),
        _buildCategorySelector(context, controller),
      ],
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    CategoryController controller,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: controller.categories.map((category) {
        final isSelected = controller.selectedCategory == category;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              controller.selectCategory(category);
            }
          },
        );
      }).toList(),
    );
  }

  // 文件大小筛选器
  Widget _buildFileSizeFilter(
    BuildContext context,
    CategoryController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '文件大小范围',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (controller.selectedSizeRange != null)
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('清除'),
                  onPressed: controller.clearSizeRange,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.sizeRanges.keys.map((range) {
              final isSelected = controller.selectedSizeRange == range;
              return FilterChip(
                label: Text(range),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectSizeRange(range);
                  } else {
                    controller.clearSizeRange();
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 时间筛选器
  Widget _buildDateFilter(BuildContext context, CategoryController controller) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '时间范围',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('选择时间'),
                onPressed: () => _showDateRangePicker(context, controller),
              ),
            ],
          ),
          const SizedBox(height: 12),
          controller.selectedDateRange != null
              ? Chip(
                  label: Text(
                    '${_formatDate(controller.selectedDateRange!.start)} - ${_formatDate(controller.selectedDateRange!.end)}',
                  ),
                  onDeleted: controller.clearDateRange,
                  deleteIcon: const Icon(Icons.clear, size: 18),
                )
              : Text(
                  '未选择时间范围',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ],
      ),
    );
  }

  // 显示日期范围选择器
  Future<void> _showDateRangePicker(
    BuildContext context,
    CategoryController controller,
  ) async {
    final now = DateTime.now();
    final initialRange =
        controller.selectedDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      controller.selectDateRange(picked);
    }
  }

  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:pasteboard/pasteboard.dart';
import 'package:kuroshot/utils/logger.dart';

import '../../../shared/widgets/app_snack_bar.dart';
import 'controllers/library_controller.dart';
import 'widgets/screenshot_card.dart';
import 'widgets/screenshot_context_menu.dart';
import 'widgets/page_input.dart';
import 'widgets/sort_menu_button.dart';
import 'widgets/library_search_bar.dart';

class ScreenshotLibraryPage extends StatefulWidget {
  const ScreenshotLibraryPage({super.key});

  @override
  State<ScreenshotLibraryPage> createState() => _ScreenshotLibraryPageState();
}

class _ScreenshotLibraryPageState extends State<ScreenshotLibraryPage> {
  @override
  void dispose() {
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final menuButtonStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.onSurface, // 按钮文字和图标颜色跟随主题
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 使用 Consumer 监听 LibraryController 的变化
      body: Consumer<LibraryController>(
        builder: (context, controller, child) {
          return CustomScrollView(
            slivers: [
              // 顶部工具栏
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: controller.isSelectionMode
                      ? _buildSelectionToolbar(context, controller)
                      : _buildNormalToolbar(
                          context,
                          controller,
                          menuButtonStyle,
                          colorScheme,
                        ),
                ),
              ),

              // 截图展示
              if (controller.screenshots.isEmpty && !controller.isLoading)
                SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: Text(
                      "暂无截图，请点击右上角添加",
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
                          await controller.toggleFavorite(screenshot.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar(
                                context,
                                message: wasFavorite ? '已取消收藏' : '已收藏',
                              ),
                            );
                          }
                        },
                        onMoveToTrash: () {
                          controller.selectedIds.add(screenshot.id);
                          controller.deleteSelected();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar(context, message: '已移至回收站'),
                            );
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

  Widget _buildNormalToolbar(
    BuildContext context,
    LibraryController controller,
    ButtonStyle menuButtonStyle,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Text(
          "图库",
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

        //右侧菜单
        const LibrarySearchBar(),

        TextButton.icon(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.image,
            );
            if (result != null && context.mounted) {
              final paths = result.paths.whereType<String>().toList();
              context.read<LibraryController>().importFiles(paths);
              ScaffoldMessenger.of(context).showSnackBar(
                AppSnackBar(context, message: '已添加 ${paths.length} 张截图'),
              );
            }
          },
          icon: const Icon(Icons.add, size: 20),
          label: const Text("添加截图"),
          style: menuButtonStyle,
        ),

        SortMenuButton(style: menuButtonStyle),

        MenuAnchor(
          alignmentOffset: const Offset(-105, 0), // 批量删除微调位置
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_horiz),
              color: colorScheme.onSurface,
              tooltip: "更多",
            );
          },
          menuChildren: [
            MenuItemButton(
              onPressed: () {
                context.read<LibraryController>().toggleSelectionMode();
              },
              leadingIcon: const Icon(Icons.delete_outline),
              child: const Text("批量删除"),
            ),
            MenuItemButton(
              onPressed: () {
                context.read<LibraryController>().updatePage(1);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(AppSnackBar(context, message: '成功刷新截图列表'));
                }
              },
              leadingIcon: const Icon(Icons.refresh),
              child: const Text("刷新"),
            ),
            Consumer<LibraryController>(
              builder: (context, ctrl, child) {
                return MenuItemButton(
                  onPressed: () {
                    ctrl.toggleFavoritesFilter();
                  },
                  leadingIcon: Icon(
                    ctrl.showOnlyFavorites ? Icons.star : Icons.star_outline,
                  ),
                  child: Text(ctrl.showOnlyFavorites ? "显示全部截图" : "只显示收藏截图"),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar(
    BuildContext context,
    LibraryController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCount = controller.selectedIds.length;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => controller.toggleSelectionMode(),
              icon: const Icon(Icons.close),
              tooltip: "取消选择",
            ),
            const SizedBox(width: 16),
            Text(
              "已选择 $selectedCount 项",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => controller.selectAll(),
              icon: const Icon(Icons.select_all),
              label: const Text("全选本页"),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => controller.deselectAll(),
              icon: const Icon(Icons.deselect),
              label: const Text("取消全选"),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: selectedCount > 0
                  ? () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("确认删除"),
                          content: Text(
                            "确定要删除选中的 $selectedCount 张截图吗？后续可从回收站恢复。",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("取消"),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.deleteSelected();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  AppSnackBar(
                                    context,
                                    message: '已将 $selectedCount 张截图移至回收站',
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              ),
                              child: const Text("删除"),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.delete),
              label: const Text("删除"),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

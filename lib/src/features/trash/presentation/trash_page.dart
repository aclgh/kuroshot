import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_snack_bar.dart';
import 'controllers/trash_controller.dart';
import '../../screenshot_library/presentation/widgets/screenshot_card.dart';
import '../../screenshot_library/presentation/widgets/page_input.dart';
import '../../screenshot_library/presentation/widgets/screenshot_context_menu.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
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
      final controller = context.read<TrashController>();

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

    final menuButtonStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.onSurface, // 按钮文字和图标颜色跟随主题
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 使用 Consumer 监听 TrashController 的变化
      body: Consumer<TrashController>(
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
                      "回收站为空",
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
                        onRestore: () async {
                          controller.selectedIds.add(screenshot.id);
                          final success = await controller.restoreSelected();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar(
                                context,
                                message: success
                                    ? '已恢复到图库'
                                    : controller.lastError ?? '恢复失败',
                              ),
                            );
                            if (success) {
                              controller.clearError();
                            }
                          }
                        },
                        onPermanentlyDelete: () {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("确认彻底删除"),
                                content: const Text("确定要彻底删除这张截图吗？此操作不可恢复。"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("取消"),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      controller.selectedIds.add(screenshot.id);
                                      final success = await controller
                                          .permanentlyDeleteSelected();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          AppSnackBar(
                                            context,
                                            message: success
                                                ? '已彻底删除截图'
                                                : controller.lastError ??
                                                      '彻底删除失败',
                                          ),
                                        );
                                        if (success) {
                                          controller.clearError();
                                        }
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.error,
                                      foregroundColor: colorScheme.onError,
                                    ),
                                    child: const Text("彻底删除"),
                                  ),
                                ],
                              ),
                            );
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
    TrashController controller,
    ButtonStyle menuButtonStyle,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Text(
          "回收站",
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

        MenuAnchor(
          style: const MenuStyle(alignment: Alignment.bottomRight),
          alignmentOffset: const Offset(-105, 0), // 批量操作微调位置
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
                context.read<TrashController>().toggleSelectionMode();
              },
              leadingIcon: const Icon(Icons.restore),
              child: const Text("批量操作"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar(
    BuildContext context,
    TrashController controller,
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
                          title: const Text("确认恢复"),
                          content: Text("确定要恢复选中的 $selectedCount 张截图吗？"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("取消"),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                final success = await controller
                                    .restoreSelected();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    AppSnackBar(
                                      context,
                                      message: success
                                          ? '已恢复 $selectedCount 张截图'
                                          : controller.lastError ?? '恢复失败',
                                    ),
                                  );
                                  if (success) {
                                    controller.clearError();
                                  }
                                }
                              },
                              child: const Text("恢复"),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.restore),
              label: const Text("恢复"),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: selectedCount > 0
                  ? () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("确认彻底删除"),
                          content: Text(
                            "确定要彻底删除选中的 $selectedCount 张截图吗？此操作不可恢复。",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("取消"),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                final success = await controller
                                    .permanentlyDeleteSelected();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    AppSnackBar(
                                      context,
                                      message: success
                                          ? '已彻底删除 $selectedCount 张截图'
                                          : controller.lastError ?? '彻底删除失败',
                                    ),
                                  );
                                  if (success) {
                                    controller.clearError();
                                  }
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              ),
                              child: const Text("彻底删除"),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.delete_forever),
              label: const Text("彻底删除"),
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

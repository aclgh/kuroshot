import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/library_controller.dart';
import 'widgets/screenshot_card.dart';
import 'widgets/page_input.dart';
import 'widgets/sort_menu_button.dart';

class ScreenshotLibraryPage extends StatelessWidget {
  const ScreenshotLibraryPage({super.key});

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
                  child: Row(
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
                      TextButton.icon(
                        onPressed: () {
                          // TODO: 实现搜索逻辑
                        },
                        icon: const Icon(Icons.search, size: 20),
                        label: const Text("搜索"),
                        style: menuButtonStyle,
                      ),

                      TextButton.icon(
                        onPressed: () {
                          // TODO: 实现过滤逻辑
                        },
                        icon: const Icon(Icons.filter_alt_outlined, size: 20),
                        label: const Text("过滤"),
                        style: menuButtonStyle,
                      ),

                      TextButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                            type: FileType.image,
                          );
                          if (result != null && context.mounted) {
                            final paths = result.paths
                                .whereType<String>()
                                .toList();
                            context.read<LibraryController>().importFiles(
                              paths,
                            );
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text("添加截图"),
                        style: menuButtonStyle,
                      ),

                      SortMenuButton(style: menuButtonStyle),

                      IconButton(
                        onPressed: () {
                          // TODO: 显示更多菜单
                        },
                        icon: const Icon(Icons.more_horiz),
                        color: colorScheme.onSurface,
                        tooltip: "更多",
                      ),
                    ],
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
                      return ScreenshotCard(screenshot: screenshot);
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
}

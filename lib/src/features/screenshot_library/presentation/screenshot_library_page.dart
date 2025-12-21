import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/presentation/controllers/settings_controller.dart';

class ScreenshotLibraryPage extends StatelessWidget {
  const ScreenshotLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;

    final menuButtonStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.onSurface, // 按钮文字和图标颜色跟随主题
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text(
                "图库",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.onSurface,
                ),
              ),
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
                onPressed: () {
                  // TODO: 实现添加逻辑
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text("添加截图"),
                style: menuButtonStyle,
              ),

              TextButton.icon(
                onPressed: () {
                  // TODO: 实现排序逻辑
                },
                icon: const Icon(Icons.swap_vert, size: 20),
                label: const Text("排序"),
                style: menuButtonStyle,
              ),
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
        ],
      ),
    );
  }
}

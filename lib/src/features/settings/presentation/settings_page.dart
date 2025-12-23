import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './controllers/settings_controller.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_item.dart';
import 'widgets/settings_number_picker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            "设置",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          //外观分组
          SettingsGroup(
            title: "外观",
            subtitle: "与显示有关的设置",
            icon: Icons.palette_outlined,
            children: [
              // 主题
              SettingsItem(
                title: "应用主题",
                subtitle: "选择你喜欢的应用主题吧",
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<ThemeMode>(
                    value: controller.themeMode,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    isDense: true,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                    ),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text("跟随系统"),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text("浅色模式"),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text("深色模式"),
                      ),
                    ],
                    onChanged: (value) => controller.updateThemeMode(value),
                  ),
                ),
              ),

              // 语言
              SettingsItem(
                title: "软件语言",
                subtitle: "选择软件使用的语言",
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: controller.locale?.languageCode ?? 'zh',
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    isDense: true,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                    ),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    items: const [
                      DropdownMenuItem(value: 'zh', child: Text("简体中文")),
                      DropdownMenuItem(value: 'en', child: Text("English")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateLocale(Locale(value));
                      }
                    },
                  ),
                ),
              ),
              SettingsItem(
                title: "图库每页数量",
                subtitle: "选择图库界面每页显示的截图数量",
                trailing: SettingsNumberPicker(
                  value: controller.sqlPage,
                  step: 10,
                  min: 10,
                  onChanged: (newValue) => controller.updateSqlPage(newValue),
                ),
              ),
            ],
          ),

          // --- 示例：其他分组 ---
          const SettingsGroup(
            title: "行为",
            subtitle: "与应用行为有关的设置",
            icon: Icons.download_outlined,
            children: [SettingsItem(title: "截图快捷键", trailing: Text("未设置"))],
          ),
        ],
      ),
    );
  }
}

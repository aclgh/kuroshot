import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import './controllers/settings_controller.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_item.dart';

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
                trailing: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 减号按钮：-10
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () {
                          final newValue = controller.sqlPage - 10;
                          controller.updateSqlPage(
                            newValue > 0 ? newValue : 10,
                          ); // 最小限制为10
                        },
                      ),
                      // 中间输入框
                      SizedBox(
                        width: 40,
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller:
                              TextEditingController(
                                  text: controller.sqlPage.toString(),
                                )
                                ..selection = TextSelection.collapsed(
                                  offset: controller.sqlPage.toString().length,
                                ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            final intValue = int.tryParse(value);
                            if (intValue != null && intValue > 0) {
                              controller.updateSqlPage(intValue);
                            }
                          },
                        ),
                      ),
                      // 加号按钮：+10
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          controller.updateSqlPage(controller.sqlPage + 10);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- 示例：其他分组 ---
          const SettingsGroup(
            title: "下载行为",
            subtitle: "从信息源获取信息有关的设置",
            icon: Icons.download_outlined,
            children: [SettingsItem(title: "最大并发数", trailing: Text("3"))],
          ),
        ],
      ),
    );
  }
}

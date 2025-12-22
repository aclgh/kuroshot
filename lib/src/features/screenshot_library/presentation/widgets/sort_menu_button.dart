import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/sort_config.dart';
import '../controllers/library_controller.dart';

class SortMenuButton extends StatelessWidget {
  final ButtonStyle? style;

  const SortMenuButton({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LibraryController>();

    return MenuAnchor(
      alignmentOffset: const Offset(-13, 0), // 微调位置
      builder: (context, controller, child) {
        return TextButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.swap_vert, size: 20),
          label: const Text("排序"),
          style: style,
        );
      },
      menuChildren: [
        _buildSortSubmenu(
          context: context,
          title: "主要排序方式",
          currentConfig: controller.primarySort,
          onSelected: (config) => controller.updateSort(primary: config),
        ),
        _buildSortSubmenu(
          context: context,
          title: "次要排序方式",
          currentConfig: controller.secondarySort,
          onSelected: (config) => controller.updateSort(secondary: config),
        ),
      ],
    );
  }

  Widget _buildSortSubmenu({
    required BuildContext context,
    required String title,
    required SortConfig currentConfig,
    required ValueChanged<SortConfig> onSelected,
  }) {
    return SubmenuButton(
      menuChildren: [
        ...SortType.values.map((type) {
          return RadioMenuButton<SortType>(
            value: type,
            groupValue: currentConfig.type,
            onChanged: (value) {
              if (value != null) {
                onSelected(currentConfig.copyWith(type: value));
              }
            },
            child: Text(type.label),
          );
        }),
        const PopupMenuDivider(),
        ...SortDirection.values.map((direction) {
          return RadioMenuButton<SortDirection>(
            value: direction,
            groupValue: currentConfig.direction,
            onChanged: (value) {
              if (value != null) {
                onSelected(currentConfig.copyWith(direction: value));
              }
            },
            child: Text(direction.label),
          );
        }),
      ],
      child: Text(title),
    );
  }
}

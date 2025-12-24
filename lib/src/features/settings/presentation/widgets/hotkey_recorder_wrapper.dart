import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../controllers/hotkey_recorder_controller.dart';

class HotKeyRecorderWrapper extends StatelessWidget {
  final HotkeyRecorderController controller;
  final ValueChanged<HotKey> onHotKeyRecorded;

  const HotKeyRecorderWrapper({
    super.key,
    required this.controller,
    required this.onHotKeyRecorded,
  });

  void _handleTap() {
    if (controller.isRecording) return;
    controller.startRecording();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        // 监听录制完成事件
        if (!controller.isRecording && controller.currentHotKey != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onHotKeyRecorded(controller.currentHotKey!);
          });
        }

        return InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: controller.isRecording
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: controller.isRecording
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
            ),
            child: Text(
              controller.isRecording
                  ? '按下快捷键...'
                  : controller.getHotKeyLabel(controller.currentHotKey),
              style: TextStyle(
                color: controller.isRecording
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontSize: 13,
                fontWeight: controller.isRecording
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}

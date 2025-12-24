import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:kuroshot/utils/logger.dart';

class HotkeyRecorderController extends ChangeNotifier {
  HotKey? _currentHotKey;
  bool _isRecording = false;

  HotKey? get currentHotKey => _currentHotKey;
  bool get isRecording => _isRecording;

  HotkeyRecorderController({HotKey? initialHotKey})
    : _currentHotKey = initialHotKey {
    if (initialHotKey != null) {
      logger.i('初始化快捷键录制器，当前快捷键: ${getHotKeyLabel(initialHotKey)}');
    } else {
      logger.i('初始化快捷键录制器，无初始快捷键');
    }
  }

  /// 开始录制快捷键
  void startRecording() {
    logger.i('开始录制快捷键');
    _isRecording = true;
    notifyListeners();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /// 停止录制快捷键
  void stopRecording() {
    logger.i('停止录制快捷键');
    _isRecording = false;
    notifyListeners();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }

  /// 处理键盘事件
  bool _handleKeyEvent(KeyEvent keyEvent) {
    if (!_isRecording) return false;
    if (keyEvent is KeyUpEvent) return false;

    final physicalKeysPressed = HardwareKeyboard.instance.physicalKeysPressed;
    final key = keyEvent.logicalKey;
    logger.d('捕获键盘事件: ${key.keyLabel}');

    // 获取当前按下的修饰键列表
    final modifiers = HotKeyModifier.values
        .where((e) => e.physicalKeys.any(physicalKeysPressed.contains))
        .toList();

    if (modifiers.isNotEmpty) {
      logger.d(
        '检测到修饰键: ${modifiers.map((m) => m.toString().split(".").last).join(", ")}',
      );
    }

    // 判断当前触发事件的主键是否是修饰键本身
    final isModifierKey = _isLogicalKeyModifier(key);

    // 如果只是按下了修饰键，则不结束录制，等待用户按下主键
    if (isModifierKey) {
      logger.d('仅按下修饰键，等待主键');
      return false;
    }

    // 构建快捷键对象
    final hotKey = HotKey(
      identifier: _currentHotKey?.identifier,
      key: key,
      modifiers: modifiers,
      scope: _currentHotKey?.scope ?? HotKeyScope.system,
    );

    logger.i('录制到快捷键: ${getHotKeyLabel(hotKey)}');
    _currentHotKey = hotKey;
    stopRecording();
    return true;
  }

  /// 辅助函数：判断一个逻辑键是否属于修饰键
  bool _isLogicalKeyModifier(LogicalKeyboardKey key) {
    return [
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.metaLeft, // Win 键 / Command 键
      LogicalKeyboardKey.metaRight,
      LogicalKeyboardKey.capsLock,
      LogicalKeyboardKey.fn,
    ].contains(key);
  }

  /// 获取快捷键的显示标签
  String getHotKeyLabel(HotKey? hotKey) {
    if (hotKey == null) {
      return '点击设置';
    }

    final modifiers =
        hotKey.modifiers
            ?.map((e) {
              switch (e) {
                case HotKeyModifier.control:
                  return 'Ctrl';
                case HotKeyModifier.alt:
                  return 'Alt';
                case HotKeyModifier.shift:
                  return 'Shift';
                case HotKeyModifier.meta:
                  return 'Win';
                default:
                  return e.toString().split('.').last;
              }
            })
            .join(' + ') ??
        '';

    String keyLabel = hotKey.key.keyLabel.toUpperCase();
    if (keyLabel == ' ') keyLabel = 'SPACE';

    return modifiers.isEmpty ? keyLabel : '$modifiers + $keyLabel';
  }

  /// 更新当前快捷键
  void updateHotKey(HotKey? hotKey) {
    if (_currentHotKey == hotKey) return;
    logger.i(
      '更新快捷键: ${getHotKeyLabel(_currentHotKey)} -> ${getHotKeyLabel(hotKey)}',
    );
    _currentHotKey = hotKey;
    notifyListeners();
  }

  @override
  void dispose() {
    logger.i('释放快捷键录制器资源');
    if (_isRecording) {
      logger.w('录制器正在录制状态下被释放，强制停止录制');
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }
}

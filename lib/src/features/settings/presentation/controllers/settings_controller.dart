import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../../data/settings_service.dart';

class SettingsController with ChangeNotifier {
  final SettingsService _settingsService;

  // 构造函数注入 Service
  SettingsController(this._settingsService);

  late ThemeMode _themeMode;
  Locale? _locale;
  late int _sqlPage;
  HotKey? _screenshotHotkey;

  // Getter
  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  int get sqlPage => _sqlPage;
  HotKey? get screenshotHotkey => _screenshotHotkey;

  /// 初始化设置 (在 App 启动前调用)
  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _locale = await _settingsService.locale();
    _sqlPage = await _settingsService.sqlPage();

    final hotkeyJson = await _settingsService.screenshotHotkey();
    if (hotkeyJson != null && hotkeyJson.isNotEmpty) {
      try {
        _screenshotHotkey = HotKey.fromJson(jsonDecode(hotkeyJson));
        _registerHotkey(_screenshotHotkey!);
      } catch (e) {
        debugPrint('Error parsing hotkey: $e');
      }
    }
    notifyListeners();
  }

  /// 更新主题模式
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  /// 更新语言环境
  Future<void> updateLocale(Locale? newLocale) async {
    if (newLocale == _locale) return;
    if (newLocale == null) return;

    _locale = newLocale;
    await _settingsService.updateLocale(newLocale);
    notifyListeners();
  }

  /// 更新 SQL 每页数量
  Future<void> updateSqlPage(int newPage) async {
    if (newPage == _sqlPage) return;

    _sqlPage = newPage;
    await _settingsService.updateSqlPage(newPage);
    notifyListeners();
  }

  /// 更新截图快捷键
  Future<void> updateScreenshotHotkey(HotKey? hotKey) async {
    if (hotKey == _screenshotHotkey) return;

    // Unregister old
    final oldHotkey = _screenshotHotkey;
    if (oldHotkey != null) {
      await hotKeyManager.unregister(oldHotkey);
    }

    _screenshotHotkey = hotKey;
    final newHotkey = _screenshotHotkey;

    // Register new
    if (newHotkey != null) {
      await _registerHotkey(newHotkey);
      await _settingsService.updateScreenshotHotkey(
        jsonEncode(newHotkey.toJson()),
      );
    } else {
      await _settingsService.updateScreenshotHotkey(null);
    }

    notifyListeners();
  }

  Future<void> _registerHotkey(HotKey hotKey) async {
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        debugPrint('Screenshot hotkey pressed: ${hotKey.toJson()}');
        // TODO: Trigger screenshot
      },
    );
  }
}

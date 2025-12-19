import 'package:flutter/material.dart';
import '../../data/settings_service.dart';

class SettingsController with ChangeNotifier {
  final SettingsService _settingsService;

  // 构造函数注入 Service
  SettingsController(this._settingsService);

  late ThemeMode _themeMode;
  Locale? _locale;

  // Getter
  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  /// 初始化设置 (在 App 启动前调用)
  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _locale = await _settingsService.locale();
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
}

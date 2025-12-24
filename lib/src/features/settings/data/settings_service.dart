import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale_code';
  static const String _pageKey = 'sql_page';
  static const String _screenshotHotkeyKey = 'screenshot_hotkey';

  // 主题
  Future<ThemeMode> themeMode() async {
    final perfs = await SharedPreferences.getInstance();
    final themeIndex = perfs.getInt(_themeKey);
    if (themeIndex == null) return ThemeMode.system;
    return ThemeMode.values[themeIndex];
  }

  Future<void> updateThemeMode(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  // 语言
  Future<Locale?> locale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageTag = prefs.getString(_localeKey);

    if (languageTag == null) return null;

    // "zh-CN" to Locale Object
    if (languageTag.contains('-')) {
      final parts = languageTag.split('-');
      return Locale(parts[0], parts[1]);
    }
    return Locale(languageTag);
  }

  Future<void> updateLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.toLanguageTag()); // zh-CN like
    }
  }

  // SQL 每页数量
  Future<int> sqlPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pageKey) ?? 20;
  }

  Future<void> updateSqlPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageKey, page);
  }

  // 截图快捷键
  Future<String?> screenshotHotkey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_screenshotHotkeyKey);
  }

  Future<void> updateScreenshotHotkey(String? hotkey) async {
    final prefs = await SharedPreferences.getInstance();
    if (hotkey == null || hotkey.isEmpty) {
      await prefs.remove(_screenshotHotkeyKey);
    } else {
      await prefs.setString(_screenshotHotkeyKey, hotkey);
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/features/home/presentation/home_page.dart';
import 'src/features/settings/data/settings_service.dart';
import 'src/features/settings/presentation/controllers/settings_controller.dart';
import 'src/features/screenshot_library/presentation/controllers/library_controller.dart';
import 'src/features/screenshot_library/data/screenshot_repository.dart';
import 'src/features/screenshot_library/application/screenshot_service.dart';
import 'src/features/trash/presentation/controllers/trash_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 初始化 FFI 非移动端数据库支持
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final settingsService = SettingsService();
  final settingsController = SettingsController(settingsService);
  await settingsController.loadSettings();
  final screenshotRepository = ScreenshotRepository();
  final screenshotService = ScreenshotService(screenshotRepository);

  runApp(
    MultiProvider(
      providers: [
        // 提供设置控制器
        ChangeNotifierProvider.value(value: settingsController),

        // 提供基础服务（如果它们不是 ChangeNotifier，可以用 Provider）
        Provider.value(value: screenshotRepository),
        Provider.value(value: screenshotService),

        // 使用 ProxyProvider 联动 LibraryController
        ChangeNotifierProxyProvider<SettingsController, LibraryController>(
          lazy: false,
          create: (context) => LibraryController(
            service: context.read<ScreenshotService>(),
            repository: context.read<ScreenshotRepository>(),
          ),
          update: (context, settings, library) {
            // 当 settingsController 通知变化时，这里会被调用
            return library!..updateConfig(pageSize: settings.sqlPage);
          },
        ),
        ChangeNotifierProxyProvider<SettingsController, TrashController>(
          lazy: false,
          create: (context) => TrashController(
            service: context.read<ScreenshotService>(),
            repository: context.read<ScreenshotRepository>(),
          ),
          update: (context, settings, trash) {
            return trash!..updateConfig(pageSize: settings.sqlPage);
          },
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'KuroShot',

      // 主题设置
      themeMode: settingsController.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Microsoft YaHei',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Microsoft YaHei',
      ),

      // 语言设置
      locale: settingsController.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', ''), // Chinese
      ],

      home: const HomePage(),
    );
  }
}

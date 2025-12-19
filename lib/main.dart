import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 引入国际化包

import 'src/features/home/presentation/home_page.dart';
import 'src/features/settings/data/settings_service.dart';
import 'src/features/settings/presentation/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  final settingsController = SettingsController(settingsService);

  await settingsController.loadSettings();

  runApp(MainApp(settingsController: settingsController));
}

class MainApp extends StatelessWidget {
  final SettingsController settingsController;
  const MainApp({super.key, required this.settingsController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
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
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
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
      },
    );
  }
}

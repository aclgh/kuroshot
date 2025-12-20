import 'package:flutter/material.dart';

import 'controllers/home_navigation_controller.dart';
import 'widgets/nav_button.dart';
import '../../settings/presentation/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeNavigationController _controller = HomeNavigationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 72,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    NavButton(
                      icon: Icons.home,
                      isSelected:
                          _controller.currentSection == HomeSection.home,
                      onTap: () => _controller.changeSection(HomeSection.home),
                    ),
                    NavButton(
                      icon: Icons.photo_library,
                      isSelected:
                          _controller.currentSection == HomeSection.gallery,
                      onTap: () =>
                          _controller.changeSection(HomeSection.gallery),
                    ),
                    const Spacer(),
                    NavButton(
                      icon: Icons.settings,
                      isSelected:
                          _controller.currentSection == HomeSection.settings,
                      onTap: () =>
                          _controller.changeSection(HomeSection.settings),
                    ),
                    NavButton(
                      icon: Icons.info_outline,
                      isSelected:
                          _controller.currentSection == HomeSection.about,
                      onTap: () => _controller.changeSection(HomeSection.about),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_controller.currentSection) {
      case HomeSection.home:
        return const Center(child: Text("主页内容"));
      case HomeSection.gallery:
        return const Center(child: Text("相册内容"));
      case HomeSection.settings:
        return const SettingsPage();
      case HomeSection.about:
        return const Center(child: Text("关于内容"));
    }
  }
}

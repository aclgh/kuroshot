import 'package:flutter/material.dart';

enum HomeSection { home, gallery, category, recycleBin, settings, about }

class HomeNavigationController extends ChangeNotifier {
  HomeSection _currentSection = HomeSection.home;

  HomeSection get currentSection => _currentSection;

  void changeSection(HomeSection section) {
    if (_currentSection != section) {
      _currentSection = section;
      notifyListeners();
    }
    return;
  }

  int get currentIndex => HomeSection.values.indexOf(_currentSection);

  void setIndex(int index) {
    if (index >= 0 && index < HomeSection.values.length) {
      changeSection(HomeSection.values[index]);
    }
  }
}

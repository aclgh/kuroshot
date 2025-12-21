import 'package:flutter/material.dart';
import 'package:kuroshot/utils/logger.dart';

import '../../domain/screenshot.dart';
import '../../data/screenshot_repository.dart';
import '../../application/screenshot_service.dart';

class LibraryController extends ChangeNotifier {
  final ScreenshotService _service;
  final ScreenshotRepository _repository;
  int _pageSize = 20;
  int _page = 1;

  //stats
  List<Screenshot> _screenshots = [];
  bool _isLoading = false;

  // Getters
  List<Screenshot> get screenshots => _screenshots;
  bool get isLoading => _isLoading;

  LibraryController({
    required ScreenshotService service,
    required ScreenshotRepository repository,
  }) : _service = service,
       _repository = repository {
    _loadPage(_page);
  }

  void updateConfig({required int pageSize}) {
    // 如果新页码和当前一致，则不处理，避免重复刷新
    if (_pageSize == pageSize) return;
    print(1);
    logger.i("更新图库每页数量: $_pageSize -> $pageSize");
    _pageSize = pageSize;
    // 回到首页
    _loadPage(1);
  }

  void updatePage(int page) {
    if (_page == page) return;
    _page = page;
    _loadPage(page);
  }

  Future<void> _loadPage(int page) async {
    _isLoading = true;
    notifyListeners();

    try {
      _screenshots = await _repository.getScreenshotsPaged(
        page: page,
        pageSize: _pageSize,
      );
    } catch (e) {
      logger.e("加载截图失败: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

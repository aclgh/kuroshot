import 'package:flutter/material.dart';
import 'package:kuroshot/utils/logger.dart';

import '../../domain/screenshot.dart';
import '../../domain/sort_config.dart';
import '../../data/screenshot_repository.dart';
import '../../application/screenshot_service.dart';

class LibraryController extends ChangeNotifier {
  final ScreenshotService _service;
  final ScreenshotRepository _repository;
  int _pageSize = 20;
  int _page = 1;
  int _allPages = 1;

  SortConfig _primarySort = const SortConfig(
    type: SortType.timestamp,
    direction: SortDirection.descending,
  );
  SortConfig _secondarySort = const SortConfig(
    type: SortType.filesize,
    direction: SortDirection.ascending,
  );

  String _searchQuery = '';

  //stats
  List<Screenshot> _screenshots = [];
  bool _isLoading = false;

  // Getters
  List<Screenshot> get screenshots => _screenshots;
  bool get isLoading => _isLoading;
  int get page => _page;
  int get allPages => _allPages;
  SortConfig get primarySort => _primarySort;
  SortConfig get secondarySort => _secondarySort;
  String get searchQuery => _searchQuery;

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
    logger.i("更新图库每页数量: $_pageSize -> $pageSize");
    _pageSize = pageSize;
    _getAllPages();
    // 回到首页
    _loadPage(1);
  }

  void updatePage(int page) {
    if (_page == page) return;
    _page = page;
    _loadPage(page);
  }

  void updateSort({SortConfig? primary, SortConfig? secondary}) {
    if (primary != null) _primarySort = primary;
    if (secondary != null) _secondarySort = secondary;

    // 重置到第一页并重新加载
    _page = 1;
    _loadPage(_page);
  }

  void search(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _page = 1;
    _loadPage(_page);
  }

  Future<void> _getAllPages() async {
    final totalCount = await _repository.getScreenshotCount(
      searchQuery: _searchQuery,
    );
    _allPages = (totalCount / _pageSize).ceil();
  }

  Future<void> _loadPage(int page) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 每次加载页面时同时也更新总页数，以防数据变动
      await _getAllPages();

      _screenshots = await _repository.getScreenshotsPaged(
        page: page,
        pageSize: _pageSize,
        primarySort: _primarySort,
        secondarySort: _secondarySort,
        searchQuery: _searchQuery,
      );
      logger.i("加载第 $page 页截图，共 ${_screenshots.length} 张");
    } catch (e) {
      logger.e("加载截图失败: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importFiles(List<String> paths) async {
    if (paths.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _service.importFiles(paths);

      // 导入完成后，通常重置回第一页以显示最新导入的内容
      _page = 1;
      await _loadPage(_page);

      logger.i("成功导入 ${paths.length} 个文件");
    } catch (e) {
      logger.e("导入过程发生错误: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

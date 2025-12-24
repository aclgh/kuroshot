import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kuroshot/utils/logger.dart';

import '../../domain/screenshot.dart';
import '../../domain/sort_config.dart';
import '../../data/screenshot_repository.dart';
import '../../application/screenshot_service.dart';

class LibraryController extends ChangeNotifier {
  final ScreenshotService _service;
  final ScreenshotRepository _repository;
  late final StreamSubscription<void> _subscription;
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
  bool _showOnlyFavorites = false;

  // Selection
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  //stats
  List<Screenshot> _screenshots = [];
  bool _isLoading = false;
  String? _lastError;

  // Getters
  List<Screenshot> get screenshots => _screenshots;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get page => _page;
  int get allPages => _allPages;
  SortConfig get primarySort => _primarySort;
  SortConfig get secondarySort => _secondarySort;
  String get searchQuery => _searchQuery;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => _selectedIds;
  bool get showOnlyFavorites => _showOnlyFavorites;

  LibraryController({
    required ScreenshotService service,
    required ScreenshotRepository repository,
  }) : _service = service,
       _repository = repository {
    // 监听 Service 层的数据变更流（包括删除、恢复等操作）
    _subscription = _service.onScreenshotsChanged.listen((_) {
      logger.i("检测到数据变更，刷新图库");
      _loadPage(_page);
    });
    _loadPage(_page);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
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

  Future<void> toggleFavoritesFilter() async {
    _showOnlyFavorites = !_showOnlyFavorites;
    _page = 1;
    await _loadPage(_page);
  }

  Future<void> _getAllPages() async {
    final totalCount = await _repository.getScreenshotCount(
      searchQuery: _searchQuery,
      showOnlyFavorites: _showOnlyFavorites,
    );
    _allPages = (totalCount / _pageSize).ceil();
  }

  Future<void> _loadPage(int page) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 每次加载页面时同时也更新总页数，以防数据变动
      await _getAllPages();

      final rawScreenshots = await _repository.getScreenshotsPaged(
        page: page,
        pageSize: _pageSize,
        primarySort: _primarySort,
        secondarySort: _secondarySort,
        searchQuery: _searchQuery,
        showOnlyFavorites: _showOnlyFavorites,
      );

      // 并行检查文件是否存在，过滤掉不存在的文件
      final validScreenshots = await Future.wait(
        rawScreenshots.map((s) async {
          return await File(s.path).exists() ? s : null;
        }),
      );

      _screenshots = validScreenshots.whereType<Screenshot>().toList();

      logger.i(
        "加载第 $page 页截图，共 ${_screenshots.length} 张 (已隐藏 ${rawScreenshots.length - _screenshots.length} 个丢失文件) [仅收藏:$_showOnlyFavorites]",
      );
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

      // 导入完成后，重置回第一页以显示最新导入的内容
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

  // Selection Methods
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_screenshots.map((s) => s.id));
    notifyListeners();
  }

  void deselectAll() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<bool> deleteSelected() async {
    if (_selectedIds.isEmpty) return false;

    _lastError = null;
    try {
      await _service.deleteScreenshots(_selectedIds.toList());
      _selectedIds.clear();
      _isSelectionMode = false;
      // Service 的操作会触发 onScreenshotsChanged，自动刷新页面
      return true;
    } catch (e) {
      logger.e("删除失败: $e");
      _lastError = "删除失败: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFavorite(String id) async {
    _lastError = null;
    try {
      await _service.toggleFavorite(id);
      // 不需要重新加载整页，service的stream会自动触发刷新
      return true;
    } catch (e) {
      logger.e("切换收藏状态失败: $e");
      _lastError = "切换收藏状态失败: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }
}

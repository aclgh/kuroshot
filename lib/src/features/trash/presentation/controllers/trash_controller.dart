import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kuroshot/utils/logger.dart';

import '../../../screenshot_library/domain/screenshot.dart';
import '../../../screenshot_library/domain/sort_config.dart';
import '../../../screenshot_library/data/screenshot_repository.dart';
import '../../../screenshot_library/application/screenshot_service.dart';

class TrashController extends ChangeNotifier {
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

  TrashController({
    required ScreenshotService service,
    required ScreenshotRepository repository,
  }) : _service = service,
       _repository = repository {
    // 订阅 Service 的变更流
    _subscription = _service.onScreenshotsChanged.listen((_) {
      logger.i("检测到数据变更，刷新回收站");
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
    logger.i("更新回收站每页数量: $_pageSize -> $pageSize");
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
    final totalCount = await _repository.getDeletedScreenshotCount(
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

      // 只获取已删除的截图 (isDeleted = 1)
      final rawScreenshots = await _repository.getDeletedScreenshotsPaged(
        page: page,
        pageSize: _pageSize,
        primarySort: _primarySort,
        secondarySort: _secondarySort,
        searchQuery: _searchQuery,
      );

      // 并行检查文件是否存在，过滤掉不存在的文件
      final validScreenshots = await Future.wait(
        rawScreenshots.map((s) async {
          return await File(s.path).exists() ? s : null;
        }),
      );

      _screenshots = validScreenshots.whereType<Screenshot>().toList();

      logger.i(
        "加载第 $page 页回收站截图，共 ${_screenshots.length} 张 (已隐藏 ${rawScreenshots.length - _screenshots.length} 个丢失文件)",
      );
    } catch (e) {
      logger.e("加载回收站截图失败: $e");
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

  // 恢复选中的截图
  Future<bool> restoreSelected() async {
    if (_selectedIds.isEmpty) return false;

    _lastError = null;
    try {
      await _service.restoreScreenshots(_selectedIds.toList());
      _selectedIds.clear();
      _isSelectionMode = false;
      return true;
    } catch (e) {
      logger.e("恢复失败: $e");
      _lastError = "恢复失败: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 彻底删除选中的截图
  Future<bool> permanentlyDeleteSelected() async {
    if (_selectedIds.isEmpty) return false;

    _lastError = null;
    try {
      await _service.removeScreenshots(_selectedIds.toList());
      _selectedIds.clear();
      _isSelectionMode = false;
      return true;
    } catch (e) {
      logger.e("彻底删除失败: $e");
      _lastError = "彻底删除失败: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

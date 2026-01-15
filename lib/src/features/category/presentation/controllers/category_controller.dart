import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kuroshot/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../../../screenshot_library/domain/screenshot.dart';
import '../../../screenshot_library/data/screenshot_repository.dart';
import '../../../screenshot_library/application/screenshot_service.dart';

class CategoryController extends ChangeNotifier {
  final ScreenshotRepository _repository;
  final ScreenshotService _service;

  // 分类列表
  final List<String> _categories = ['游戏', '文件大小', '时间', '标签'];

  // 当前选中的分类
  String _selectedCategory = '游戏';

  // 截图列表
  List<Screenshot> _screenshots = [];

  // 分页相关
  int _page = 1;
  int _pageSize = 20;
  int _totalCount = 0;

  // 加载状态
  bool _isLoading = false;
  String? _lastError;

  // Selection
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // 文件大小范围（单位：字节）
  String? _selectedSizeRange;
  final Map<String, (int?, int?)> _sizeRanges = {
    '< 100KB': (null, 100 * 1024),
    '100KB - 500KB': (100 * 1024, 500 * 1024),
    '500KB - 1MB': (500 * 1024, 1024 * 1024),
    '1MB - 5MB': (1024 * 1024, 5 * 1024 * 1024),
    '5MB - 10MB': (5 * 1024 * 1024, 10 * 1024 * 1024),
    '> 10MB': (10 * 1024 * 1024, null),
  };

  // 时间范围
  DateTimeRange? _selectedDateRange;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  List<Screenshot> get screenshots => _screenshots;
  int get page => _page;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get allPages => (_totalCount / _pageSize).ceil();
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => _selectedIds;
  String? get selectedSizeRange => _selectedSizeRange;
  Map<String, (int?, int?)> get sizeRanges => _sizeRanges;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  CategoryController({
    required ScreenshotRepository repository,
    required ScreenshotService service,
  }) : _repository = repository,
       _service = service {
    _loadScreenshots();
  }

  // 选择分类
  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _page = 1; // 重置到第一页
      _loadScreenshots();
      notifyListeners();
    }
  }

  // 更新页码
  void updatePage(int newPage) {
    if (newPage >= 1 && newPage <= allPages && newPage != _page) {
      _page = newPage;
      _loadScreenshots();
      notifyListeners();
    }
  }

  void updateConfig({required int pageSize}) {
    // 如果新页码和当前一致，则不处理，避免重复刷新
    if (_pageSize == pageSize) return;
    logger.i("更新分类页面每页数量: $_pageSize -> $pageSize");
    _pageSize = pageSize;
    // 回到首页
    _page = 1;
    _loadScreenshots();
  }

  // 加载截图数据
  Future<void> _loadScreenshots() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 计算总数
      await _getTotalCount();

      // 如果请求的页码超出范围，调整到最后一页
      if (_page > allPages && allPages > 0) {
        _page = allPages;
        logger.i("请求页码超出范围，调整到第 $_page 页");
      }

      // 根据不同的分类类型加载数据
      List<Screenshot> rawScreenshots;

      switch (_selectedCategory) {
        case '文件大小':
          rawScreenshots = await _loadByFileSize();
          break;
        case '时间':
          rawScreenshots = await _loadByTime();
          break;
        case '标签':
          rawScreenshots = await _loadByTags();
          break;
        case '游戏':
        default:
          rawScreenshots = await _loadByApp();
          break;
      }

      // 并行检查文件是否存在，过滤掉不存在的文件
      final validScreenshots = await Future.wait(
        rawScreenshots.map((s) async {
          return await File(s.path).exists() ? s : null;
        }),
      );

      _screenshots = validScreenshots.whereType<Screenshot>().toList();

      logger.i(
        "加载第 $_page 页截图 [分类: $_selectedCategory]，共 ${_screenshots.length} 张 (已隐藏 ${rawScreenshots.length - _screenshots.length} 个丢失文件)",
      );

      // 如果当前页没有数据且不是第一页，自动跳转到上一页
      if (_screenshots.isEmpty && _page > 1) {
        logger.i("第 $_page 页无数据，跳转到第 ${_page - 1} 页");
        _page = _page - 1;
        _isLoading = false;
        notifyListeners();
        // 递归加载上一页
        return _loadScreenshots();
      }
    } catch (e) {
      logger.e('加载截图失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取总数
  Future<void> _getTotalCount() async {
    final db = await _repository.database;
    String whereClause = 'isDeleted = 0';
    List<dynamic> whereArgs = [];

    // 根据不同分类类型添加筛选条件
    if (_selectedCategory == '文件大小' && _selectedSizeRange != null) {
      final range = _sizeRanges[_selectedSizeRange];
      if (range != null) {
        if (range.$1 != null) {
          whereClause += ' AND filesize >= ?';
          whereArgs.add(range.$1);
        }
        if (range.$2 != null) {
          whereClause += ' AND filesize <= ?';
          whereArgs.add(range.$2);
        }
      }
    } else if (_selectedCategory == '时间' && _selectedDateRange != null) {
      whereClause += ' AND timestamp >= ? AND timestamp <= ?';
      whereArgs.add(_selectedDateRange!.start.millisecondsSinceEpoch);
      whereArgs.add(
        _selectedDateRange!.end
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch,
      );
    } else if (_selectedCategory == '游戏' && _selectedSizeRange != null) {
      // 这里可以根据应用名称筛选
      whereClause += ' AND appName = ?';
      whereArgs.add(_selectedSizeRange);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM screenshots WHERE $whereClause',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    _totalCount = Sqflite.firstIntValue(result) ?? 0;
  }

  // 按应用加载
  Future<List<Screenshot>> _loadByApp() async {
    final db = await _repository.database;
    final offset = (_page - 1) * _pageSize;

    String whereClause = 'isDeleted = 0 AND appName IS NOT NULL';
    List<dynamic> whereArgs = [];

    // 如果选择了特定应用
    if (_selectedSizeRange != null) {
      whereClause += ' AND appName = ?';
      whereArgs.add(_selectedSizeRange);
    }

    final maps = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: _pageSize,
      offset: offset,
    );

    return maps.map((m) => _repository.fromMap(m)).toList();
  }

  // 按文件大小加载
  Future<List<Screenshot>> _loadByFileSize() async {
    final db = await _repository.database;
    final offset = (_page - 1) * _pageSize;

    String whereClause = 'isDeleted = 0';
    List<dynamic> whereArgs = [];

    if (_selectedSizeRange != null) {
      final range = _sizeRanges[_selectedSizeRange];
      if (range != null) {
        if (range.$1 != null) {
          whereClause += ' AND filesize >= ?';
          whereArgs.add(range.$1);
        }
        if (range.$2 != null) {
          whereClause += ' AND filesize <= ?';
          whereArgs.add(range.$2);
        }
      }
    }

    final maps = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'filesize DESC, timestamp DESC',
      limit: _pageSize,
      offset: offset,
    );

    return maps.map((m) => _repository.fromMap(m)).toList();
  }

  // 按时间加载
  Future<List<Screenshot>> _loadByTime() async {
    final db = await _repository.database;
    final offset = (_page - 1) * _pageSize;

    String whereClause = 'isDeleted = 0';
    List<dynamic> whereArgs = [];

    if (_selectedDateRange != null) {
      whereClause += ' AND timestamp >= ? AND timestamp <= ?';
      whereArgs.add(_selectedDateRange!.start.millisecondsSinceEpoch);
      whereArgs.add(
        _selectedDateRange!.end
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch,
      );
    }

    final maps = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: _pageSize,
      offset: offset,
    );

    return maps.map((m) => _repository.fromMap(m)).toList();
  }

  // 按标签加载
  Future<List<Screenshot>> _loadByTags() async {
    final db = await _repository.database;
    final offset = (_page - 1) * _pageSize;

    String whereClause = 'isDeleted = 0 AND tags IS NOT NULL AND tags != ""';
    List<dynamic> whereArgs = [];

    final maps = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: _pageSize,
      offset: offset,
    );

    return maps.map((m) => _repository.fromMap(m)).toList();
  }

  // 刷新数据
  Future<void> refresh() async {
    await _loadScreenshots();
  }

  // 添加新分类
  void addCategory(String categoryName) {
    if (!_categories.contains(categoryName)) {
      _categories.add(categoryName);
      notifyListeners();
    }
  }

  // 删除分类
  void removeCategory(String categoryName) {
    if (categoryName != '全部' && _categories.contains(categoryName)) {
      _categories.remove(categoryName);
      if (_selectedCategory == categoryName) {
        _selectedCategory = '全部';
        _loadScreenshots();
      }
      notifyListeners();
    }
  }

  // 重命名分类
  void renameCategory(String oldName, String newName) {
    final index = _categories.indexOf(oldName);
    if (index != -1 && oldName != '全部') {
      _categories[index] = newName;
      if (_selectedCategory == oldName) {
        _selectedCategory = newName;
      }
      notifyListeners();
    }
  }

  // 选择文件大小范围
  void selectSizeRange(String? sizeRange) {
    if (_selectedSizeRange != sizeRange) {
      _selectedSizeRange = sizeRange;
      _page = 1; // 重置到第一页
      _loadScreenshots();
      notifyListeners();
    }
  }

  // 选择时间范围
  void selectDateRange(DateTimeRange? dateRange) {
    if (_selectedDateRange != dateRange) {
      _selectedDateRange = dateRange;
      _startDate = dateRange?.start;
      _endDate = dateRange?.end;
      _page = 1; // 重置到第一页
      _loadScreenshots();
      notifyListeners();
    }
  }

  // 清除文件大小范围
  void clearSizeRange() {
    _selectedSizeRange = null;
    _page = 1;
    _loadScreenshots();
    notifyListeners();
  }

  // 清除时间范围
  void clearDateRange() {
    _selectedDateRange = null;
    _startDate = null;
    _endDate = null;
    _page = 1;
    _loadScreenshots();
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
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
      // 删除后重新加载当前页
      await _loadScreenshots();
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
      // 重新加载当前页以更新状态
      await _loadScreenshots();
      return true;
    } catch (e) {
      logger.e("切换收藏状态失败: $e");
      _lastError = "切换收藏状态失败: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }
}

import 'dart:async';
import 'package:kuroshot/utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../domain/screenshot.dart';

import '../domain/sort_config.dart';

class ScreenshotRepository {
  static final ScreenshotRepository _instance =
      ScreenshotRepository._internal();
  static Database? _database;

  factory ScreenshotRepository() => _instance;

  ScreenshotRepository._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kuroshot.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    //创建 screenshot 表
    await db.execute('''
      CREATE TABLE screenshots(
        id TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        filesize INTEGER NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        format TEXT NOT NULL,
        path TEXT NOT NULL,
        fileHash TEXT,
        source TEXT NOT NULL,
        appName TEXT,
        windowTitle TEXT,
        remoteUrl TEXT,
        comment TEXT,
        description TEXT,
        tags TEXT, 
        ocrText TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  //转换
  Map<String, dynamic> _toMap(Screenshot screenshot) {
    return {
      'id': screenshot.id,
      'timestamp': screenshot.timestamp.millisecondsSinceEpoch,
      'filesize': screenshot.filesize,
      'width': screenshot.width,
      'height': screenshot.height,
      'format': screenshot.format,
      'path': screenshot.path,
      'fileHash': screenshot.fileHash,
      'source': screenshot.source,
      'appName': screenshot.appName,
      'windowTitle': screenshot.windowTitle,
      'remoteUrl': screenshot.remoteUrl,
      'comment': screenshot.comment,
      'description': screenshot.description,
      'tags': screenshot.tags.join(','), // List 转 String sqlite 不支持 List
      'ocrText': screenshot.ocrText,
      'isFavorite': screenshot.isFavorite ? 1 : 0, // bool 转 int
      'isDeleted': screenshot.isDeleted ? 1 : 0, // bool 转 int
    };
  }

  Screenshot _fromMap(Map<String, dynamic> map) {
    return Screenshot(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      filesize: map['filesize'],
      width: map['width'],
      height: map['height'],
      format: map['format'],
      path: map['path'],
      source: map['source'],
      fileHash: map['fileHash'],
      appName: map['appName'],
      windowTitle: map['windowTitle'],
      remoteUrl: map['remoteUrl'],
      comment: map['comment'],
      description: map['description'],
      tags: map['tags'] != null && map['tags'].toString().isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      ocrText: map['ocrText'],
      isFavorite: (map['isFavorite'] as int) == 1,
      isDeleted: (map['isDeleted'] as int) == 1,
    );
  }

  //CRUD
  Future<void> insertScreenshot(Screenshot screenshot) async {
    final db = await database;
    await db.insert(
      'screenshots',
      _toMap(screenshot),
      conflictAlgorithm: ConflictAlgorithm.replace, // 如果 ID 重复则覆盖
    );
  }

  Future<List<Screenshot>> getAllScreenshots() async {
    final db = await database;
    // 默认按时间倒序排列，且不显示已删除的
    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  Future<int> getScreenshotCount({
    String? searchQuery,
    bool showOnlyFavorites = false,
  }) async {
    final db = await database;
    String whereClause = 'isDeleted = 0';
    List<dynamic> whereArgs = [];

    if (showOnlyFavorites) {
      whereClause += ' AND isFavorite = 1';
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause +=
          ' AND (appName LIKE ? OR windowTitle LIKE ? OR ocrText LIKE ? OR tags LIKE ? OR comment LIKE ? OR description LIKE ?)';
      whereArgs.addAll([
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
      ]);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM screenshots WHERE $whereClause',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getDeletedScreenshotCount({String? searchQuery}) async {
    final db = await database;
    String whereClause = 'isDeleted = 1';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause +=
          ' AND (appName LIKE ? OR windowTitle LIKE ? OR ocrText LIKE ? OR tags LIKE ? OR comment LIKE ? OR description LIKE ?)';
      whereArgs.addAll([
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
      ]);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM screenshots WHERE $whereClause',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Screenshot>> getScreenshotsPaged({
    required int page,
    int? pageSize,
    SortConfig? primarySort,
    SortConfig? secondarySort,
    String? searchQuery,
    bool showOnlyFavorites = false,
  }) async {
    final db = await database;

    final int limit = pageSize ?? 20;

    // 计算偏移量
    final int offset = (page - 1) * limit;

    // 构建排序语句
    String orderBy = 'timestamp DESC';
    if (primarySort != null) {
      final primary = _getSqlSort(primarySort);
      if (secondarySort != null) {
        final secondary = _getSqlSort(secondarySort);
        orderBy = '$primary, $secondary';
      } else {
        orderBy = primary;
      }
    }

    String whereClause = 'isDeleted = 0';
    List<dynamic> whereArgs = [];

    if (showOnlyFavorites) {
      whereClause += ' AND isFavorite = 1';
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause +=
          ' AND (appName LIKE ? OR windowTitle LIKE ? OR ocrText LIKE ? OR tags LIKE ? OR comment LIKE ? OR description LIKE ?)';
      whereArgs.addAll([
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
      ]);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  Future<List<Screenshot>> getDeletedScreenshotsPaged({
    required int page,
    int? pageSize,
    SortConfig? primarySort,
    SortConfig? secondarySort,
    String? searchQuery,
  }) async {
    final db = await database;

    final int limit = pageSize ?? 20;

    // 计算偏移量
    final int offset = (page - 1) * limit;

    // 构建排序语句
    String orderBy = 'timestamp DESC';
    if (primarySort != null) {
      final primary = _getSqlSort(primarySort);
      if (secondarySort != null) {
        final secondary = _getSqlSort(secondarySort);
        orderBy = '$primary, $secondary';
      } else {
        orderBy = primary;
      }
    }

    String whereClause = 'isDeleted = 1';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause +=
          ' AND (appName LIKE ? OR windowTitle LIKE ? OR ocrText LIKE ? OR tags LIKE ? OR comment LIKE ? OR description LIKE ?)';
      whereArgs.addAll([
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
        '%$searchQuery%',
      ]);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  String _getSqlSort(SortConfig config) {
    String column;
    switch (config.type) {
      case SortType.timestamp:
        column = 'timestamp';
        break;
      case SortType.filesize:
        column = 'filesize';
        break;
      case SortType.appName:
        column = 'appName';
        break;
    }
    final direction = config.direction == SortDirection.ascending
        ? 'ASC'
        : 'DESC';
    return '$column $direction';
  }

  Future<Screenshot?> getScreenshotById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateScreenshot(Screenshot screenshot) async {
    final db = await database;
    await db.update(
      'screenshots',
      _toMap(screenshot),
      where: 'id = ?',
      whereArgs: [screenshot.id],
    );
  }

  Future<void> removeScreenshot(String id) async {
    final db = await database;
    await db.delete('screenshots', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteScreenshot(String id) async {
    final db = await database;
    // 只是标记为删除，不真正从数据库移除
    await db.update(
      'screenshots',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreScreenshot(String id) async {
    final db = await database;
    // 将 isDeleted 标记为 0，表示恢复
    await db.update(
      'screenshots',
      {'isDeleted': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(String id) async {
    final db = await database;
    final screenshot = await getScreenshotById(id);
    if (screenshot != null) {
      final newFavoriteState = screenshot.isFavorite ? 0 : 1;
      logger.i(
        'Repository: 切换收藏 ID=$id, 原状态=${screenshot.isFavorite}, 新状态=$newFavoriteState',
      );
      final rowsAffected = await db.update(
        'screenshots',
        {'isFavorite': newFavoriteState},
        where: 'id = ?',
        whereArgs: [id],
      );
      logger.i('Repository: 数据库更新完成，影响行数=$rowsAffected');
    } else {
      logger.i('Repository: 未找到ID为 $id 的截图');
    }
  }

  Future<List<Screenshot>> searchScreenshots(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'screenshots',
      where:
          'isDeleted = 0 AND (appName LIKE ? OR windowTitle LIKE ? OR ocrText LIKE ? OR tags LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }
}

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../domain/screenshot.dart';

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
}

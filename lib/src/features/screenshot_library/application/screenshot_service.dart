import 'dart:io';
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:kuroshot/utils/logger.dart';

import '../domain/screenshot.dart';
import '../data/screenshot_repository.dart';

class ScreenshotService {
  final ScreenshotRepository _repository;
  final Uuid _uuid = Uuid();

  ScreenshotService(this._repository);

  Future<void> importFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      try {
        // 获取基本文件信息
        final stat = await file.stat();

        // 获取图片尺寸
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frameInfo = await codec.getNextFrame();
        final width = frameInfo.image.width;
        final height = frameInfo.image.height;

        // 释放图片资源
        frameInfo.image.dispose();

        // 构建实体对象
        final screenshot = Screenshot(
          id: _uuid.v4(), // 生成唯一ID
          timestamp: stat.changed, // 使用文件修改时间
          filesize: stat.size,
          width: width,
          height: height,
          format: p
              .extension(path)
              .replaceAll('.', '')
              .toLowerCase(), // e.g. "png"
          path: path, // 这里目前存的是原路径
          source: 'import',
          appName: 'Unknown',
        );

        await _repository.insertScreenshot(screenshot);
      } catch (e) {
        logger.e("处理文件失败 $path: $e");
      }
    }
  }
}

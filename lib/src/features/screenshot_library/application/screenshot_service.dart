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

        final id = _uuid.v4();
        final extension = p.extension(path);
        final format = extension.replaceAll('.', '').toLowerCase();

        // 复制文件到程序根目录下的 screenshots 文件夹
        final relativePath = p.join('screenshots', '$id$extension');
        final absolutePath = p.join(Directory.current.path, relativePath);

        final storageDir = Directory(p.dirname(absolutePath));
        if (!await storageDir.exists()) {
          await storageDir.create(recursive: true);
        }
        await file.copy(absolutePath);

        // 构建实体对象
        final screenshot = Screenshot(
          id: id,
          timestamp: stat.changed, // 使用文件修改时间
          filesize: stat.size,
          width: width,
          height: height,
          format: format,
          path: relativePath,
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

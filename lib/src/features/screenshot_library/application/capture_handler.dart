import './screenshot_service.dart';
import 'package:kuroshot/utils/native_screenshot_helper.dart';

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:kuroshot/utils/logger.dart';
import 'package:kuroshot/utils/win32_helper.dart';
import 'package:image/image.dart' as img;

Future<void> captureAndImport(ScreenshotService screenshotService) async {
  File? tempFile;
  try {
    //  获取当前窗口信息
    final winInfo = Win32Helper.getForegroundWindowInfo();
    // 记录实际截图时间
    final captureTime = DateTime.now();

    // 直接内存截图
    final img.Image? capturedImage =
        await NativeScreenshotHelper.captureFullScreen();

    if (capturedImage == null) {
      logger.w("截图失败，获取到的图像为空");
      return;
    }

    // 将图片编码为 PNG 格式的字节流 (在内存中进行)
    final pngBytes = img.encodePng(capturedImage);

    // 存临时文件：
    final tempDir = await getTemporaryDirectory();
    final fileName = 'clean_capture_${Uuid().v4()}.png';
    final tempFilePath = p.join(tempDir.path, fileName);

    tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(pngBytes);

    // 导入流程，传入实际截图时间
    await screenshotService.importDetailedFiles(
      [tempFilePath],
      source: 'fullscreen',
      appName: winInfo.appName,
      windowTitle: winInfo.title,
      captureTime: captureTime,
    );

    logger.i("截图导入完成 (Native GDI 方式)");
  } catch (e, stack) {
    logger.e("截图流程异常: $e", error: e, stackTrace: stack);
  } finally {
    // 确保清理临时文件
    if (tempFile != null && await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (e) {
        logger.w("清理临时文件失败: $e");
      }
    }
  }
}

import './screenshot_service.dart';
import 'package:kuroshot/utils/native_screenshot_helper.dart';

import 'dart:io';
import 'package:win_toast/win_toast.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:kuroshot/utils/logger.dart';
import 'package:kuroshot/utils/win32_helper.dart';
import 'package:image/image.dart' as img;
import 'package:audioplayers/audioplayers.dart';

final _audioPlayer = AudioPlayer();

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

    // 导入流程，传入实际截图时间，获取最终保存的路径
    final savedPaths = await screenshotService.importDetailedFiles(
      [tempFilePath],
      source: 'fullscreen',
      appName: winInfo.appName,
      windowTitle: winInfo.title,
      captureTime: captureTime,
    );

    logger.i("截图导入完成 (Native GDI 方式)");

    await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);

    await _audioPlayer.play(AssetSource('sounds/camera1.wav'));

    // 显示 Windows 通知 (使用最终保存的路径，而不是临时路径)
    if (savedPaths.isNotEmpty) {
      await showScreenshotNotification(savedPaths.first);
    }
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

/// 显示截图保存成功的 Windows 通知
///
/// [imagePath] 保存的截图文件路径（绝对路径）
Future<void> showScreenshotNotification(String imagePath) async {
  try {
    // 初始化 WinToast (应用启动时只需初始化一次，这里每次调用也是安全的)
    await WinToast.instance().initialize(
      aumId: 'YourCompany.KuroShot',
      displayName: 'KuroShot',
      iconPath: '',
      clsid: '936C392F-9496-4F58-8D3F-6F4005D23803',
    );

    final normalizedPath = imagePath.replaceAll('\\', '/');

    // 构建 XML
    // placement="hero" 让图片显示为大横幅
    final xml =
        """
  <toast>
  <audio silent="true" />
    <visual>
      <binding template="ToastGeneric">
        <text>截图已保存</text>
        <text>点击此处查看或编辑</text>
        <image placement="hero" src="file:///$normalizedPath"/>
      </binding>
    </visual>
  </toast>
  """;

    // 4. 显示通知
    await WinToast.instance().showCustomToast(xml: xml);
    logger.i("截图通知已显示");
  } catch (e) {
    logger.e("显示截图通知失败: $e");
  }
}

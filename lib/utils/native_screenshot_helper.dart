import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:image/image.dart' as img;

class NativeScreenshotHelper {
  /// 截取全屏并返回 image 库的 Image 对象
  static Future<img.Image?> captureFullScreen() async {
    // 获取屏幕的宽和高
    final user32 = DynamicLibrary.open('user32.dll');
    final getSystemMetrics = user32
        .lookupFunction<Int32 Function(Int32 nIndex), int Function(int nIndex)>(
          'GetSystemMetrics',
        );

    // SM_CXVIRTUALSCREEN = 78, SM_CYVIRTUALSCREEN = 79 (支持多显示器)
    // 或者 SM_CXSCREEN = 0, SM_CYSCREEN = 1 (仅主屏)
    // 这里使用 VirtualScreen 以支持多显示器全屏
    final width = getSystemMetrics(78);
    final height = getSystemMetrics(79);
    final left = getSystemMetrics(76); // SM_XVIRTUALSCREEN
    final top = getSystemMetrics(77); // SM_YVIRTUALSCREEN

    // 获取桌面窗口句柄和设备上下文 (DC)
    final hwnd = GetDesktopWindow();
    final hdcScreen = GetDC(hwnd);

    // 创建兼容的内存 DC 和 Bitmap
    final hdcMem = CreateCompatibleDC(hdcScreen);
    final hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
    final hOld = SelectObject(hdcMem, hBitmap);

    // 执行 BitBlt (Bit Block Transfer)
    // 将屏幕内容复制到内存 Bitmap 中
    BitBlt(hdcMem, 0, 0, width, height, hdcScreen, left, top, SRCCOPY);

    // 提取像素数据
    final bitmapInfo = calloc<BITMAPINFO>();
    bitmapInfo.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
    bitmapInfo.ref.bmiHeader.biWidth = width;
    bitmapInfo.ref.bmiHeader.biHeight = -height; // 负数表示自顶向下
    bitmapInfo.ref.bmiHeader.biPlanes = 1;
    bitmapInfo.ref.bmiHeader.biBitCount = 32; // RGBA
    bitmapInfo.ref.bmiHeader.biCompression = BI_RGB;

    final dataSize = width * height * 4;
    final pixels = calloc<Uint8>(dataSize);

    // 获取位图数据到 pixels 指针
    GetDIBits(hdcMem, hBitmap, 0, height, pixels, bitmapInfo, DIB_RGB_COLORS);

    // 将原生数据转换为 Dart 可用的 Image 对象
    // 注意：Windows GDI 获取的数据通常是 BGRA 格式，image 库通常需要 RGBA
    final img.Image image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: pixels.asTypedList(dataSize).buffer,
      order: img.ChannelOrder.bgra, // 指定源数据是 BGRA
      numChannels: 4,
    );

    // 清理原生资源 防止OOM
    SelectObject(hdcMem, hOld);
    DeleteObject(hBitmap);
    DeleteDC(hdcMem);
    ReleaseDC(hwnd, hdcScreen);
    calloc.free(bitmapInfo);
    calloc.free(pixels);

    return image;
  }
}

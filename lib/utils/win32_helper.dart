import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowContextInfo {
  final String title;
  final String appName;
  WindowContextInfo({required this.title, required this.appName});
}

class Win32Helper {
  /// 获取当前 Windows 前台窗口的标题和应用名称
  static WindowContextInfo getForegroundWindowInfo() {
    if (!Platform.isWindows) {
      return WindowContextInfo(title: 'Unknown', appName: 'Unknown');
    }

    final hwnd = GetForegroundWindow();
    if (hwnd == 0) {
      return WindowContextInfo(title: 'Unknown', appName: 'Unknown');
    }

    // 1. 获取窗口标题
    String windowTitle = 'Unknown';
    final titleLength = GetWindowTextLength(hwnd);
    if (titleLength > 0) {
      // 分配内存 (+1 用于结尾的空字符)
      final buffer = wsalloc(titleLength + 1);
      GetWindowText(hwnd, buffer, titleLength + 1);
      windowTitle = buffer.toDartString();
      free(buffer);
    }

    // 2. 获取进程名 (AppName)
    String appName = 'Unknown';
    final processIdPtr = calloc<DWORD>();
    GetWindowThreadProcessId(hwnd, processIdPtr);
    final processId = processIdPtr.value;
    free(processIdPtr);

    // 打开进程以查询信息
    final hProcess = OpenProcess(
      PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
      FALSE,
      processId,
    );

    if (hProcess != 0) {
      final hModule = calloc<HMODULE>();
      final cbNeeded = calloc<DWORD>();
      // 获取进程的第一个模块句柄
      if (EnumProcessModules(hProcess, hModule, sizeOf<HMODULE>(), cbNeeded) !=
          0) {
        final moduleNameBuffer = wsalloc(MAX_PATH);
        // 获取模块基名称 (例如 "chrome.exe")
        if (GetModuleBaseName(
              hProcess,
              hModule.value,
              moduleNameBuffer,
              MAX_PATH,
            ) !=
            0) {
          appName = moduleNameBuffer.toDartString();
        }
        free(moduleNameBuffer);
      }
      free(hModule);
      free(cbNeeded);
      CloseHandle(hProcess);
    }

    return WindowContextInfo(title: windowTitle, appName: appName);
  }
}

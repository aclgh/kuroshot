class Screenshot {
  // --- 基础标识 ---
  final String id;
  final DateTime timestamp;

  // --- 属性 ---
  final int filesize; // bytes
  final int width;
  final int height;
  final String format; // e.g., 'png', 'jpg'
  final String path; // 本地存储路径
  final String? fileHash; // 用于去重 (MD5/SHA256)

  // --- 来源上下文 ---
  final String source; // 截图来源方式 (e.g., 'region', 'window', 'fullscreen')
  final String? appName; // 截图时前台应用
  final String? windowTitle; // 窗口标题
  final String? remoteUrl;

  // --- 内容与元数据 ---
  String? comment;
  String? description;
  List<String> tags;
  String? ocrText;

  // --- 状态 ---
  bool isFavorite;
  bool isDeleted; // 软删除

  Screenshot({
    required this.id,
    required this.timestamp,
    required this.filesize,
    required this.width,
    required this.height,
    required this.format,
    required this.path,
    required this.source,
    this.fileHash,
    this.appName,
    this.windowTitle,
    this.remoteUrl,
    this.comment,
    this.description,
    this.tags = const [],
    this.ocrText,
    this.isFavorite = false,
    this.isDeleted = false,
  });

  Screenshot copyWith({
    String? comment,
    String? description,
    List<String>? tags,
    bool? isFavorite,
    bool? isDeleted,
    String? ocrText,
  }) {
    return Screenshot(
      id: id,
      timestamp: timestamp,
      filesize: filesize,
      width: width,
      height: height,
      format: format,
      path: path,
      source: source,
      fileHash: fileHash,
      appName: appName,
      windowTitle: windowTitle,
      remoteUrl: remoteUrl,
      comment: comment ?? this.comment,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      ocrText: ocrText ?? this.ocrText,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

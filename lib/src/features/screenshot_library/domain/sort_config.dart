enum SortType {
  timestamp,
  filesize,
  appName;

  String get label {
    switch (this) {
      case SortType.timestamp:
        return '按添加时间';
      case SortType.filesize:
        return '按文件大小';
      case SortType.appName:
        return '按应用名称';
    }
  }
}

enum SortDirection {
  ascending,
  descending;

  String get label {
    switch (this) {
      case SortDirection.ascending:
        return '升序';
      case SortDirection.descending:
        return '降序';
    }
  }
}

class SortConfig {
  final SortType type;
  final SortDirection direction;

  const SortConfig({
    this.type = SortType.timestamp,
    this.direction = SortDirection.descending,
  });

  SortConfig copyWith({SortType? type, SortDirection? direction}) {
    return SortConfig(
      type: type ?? this.type,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SortConfig &&
        other.type == type &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(type, direction);
}

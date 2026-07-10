/// 路线展示用格式化（中文，演示级精度）。
String formatDurationSec(int seconds) {
  if (seconds < 60) {
    return '$seconds秒';
  }
  final int minutes = (seconds / 60).round();
  if (minutes < 60) {
    return '$minutes分钟';
  }
  final int hours = minutes ~/ 60;
  final int remainMinutes = minutes % 60;
  if (remainMinutes == 0) {
    return '$hours小时';
  }
  return '$hours小时$remainMinutes分钟';
}

String formatDistanceM(int meters) {
  if (meters < 1000) {
    return '${meters}米';
  }
  return '${(meters / 1000).toStringAsFixed(1)}公里';
}

String formatTollEstimate(num yuan) {
  if (yuan <= 0) {
    return '约 ¥0（估算）';
  }
  return '约 ¥${yuan.toStringAsFixed(0)}（估算）';
}

/// 备选路线相对推荐路线的时间/距离差文案。
String formatRouteDelta({
  required int baseDurationSec,
  required int baseDistanceM,
  required int durationSec,
  required int distanceM,
}) {
  final int durationDeltaMin = ((durationSec - baseDurationSec) / 60).round();
  final int distanceDeltaM = distanceM - baseDistanceM;

  final List<String> parts = <String>[];
  if (durationDeltaMin != 0) {
    parts.add(durationDeltaMin > 0 ? '+$durationDeltaMin分钟' : '$durationDeltaMin分钟');
  }
  if (distanceDeltaM.abs() >= 100) {
    if (distanceDeltaM.abs() < 1000) {
      parts.add(distanceDeltaM > 0 ? '+${distanceDeltaM}米' : '${distanceDeltaM}米');
    } else {
      final String km = (distanceDeltaM / 1000).toStringAsFixed(1);
      parts.add(distanceDeltaM > 0 ? '+${km}公里' : '$km公里');
    }
  }
  return parts.isEmpty ? '与推荐相近' : parts.join(' · ');
}

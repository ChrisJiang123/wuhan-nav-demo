import 'package:flutter_test/flutter_test.dart';
import 'package:wuhan_nav/core/utils/route_format.dart';

void main() {
  test('formatDurationSec 中文输出', () {
    expect(formatDurationSec(1043), '17分钟');
    expect(formatDurationSec(482), '8分钟');
  });

  test('formatDistanceM 公里换算', () {
    expect(formatDistanceM(19884), '19.9公里');
    expect(formatDistanceM(3001), '3.0公里');
  });

  test('formatRouteDelta 相对推荐路线', () {
    expect(
      formatRouteDelta(
        baseDurationSec: 2185,
        baseDistanceM: 24438,
        durationSec: 2310,
        distanceM: 25120,
      ),
      contains('+2分钟'),
    );
  });
}

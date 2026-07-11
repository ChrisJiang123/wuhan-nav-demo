#!/usr/bin/env bash
# 模拟器联调：App 经 BFF 访问 OSRM，地图显示真实道路折线。
set -euo pipefail
cd "$(dirname "$0")/.."
flutter run --dart-define=BFF_BASE_URL=http://10.0.2.2:3000 "$@"

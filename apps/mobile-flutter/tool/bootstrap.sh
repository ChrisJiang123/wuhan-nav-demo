#!/usr/bin/env bash
#
# 补齐 Flutter Android 平台层（gradle wrapper、launcher 图标、MainActivity 等）。
#
# 背景：本仓库只手写了 Dart 源码与配置（lib/、test/、pubspec.yaml、
# analysis_options.yaml），平台层含二进制文件（gradle-wrapper.jar、图标 PNG）
# 无法进 git，需要在装有 Flutter 的机器上用 `flutter create` 生成。
#
# 用法：
#   cd apps/mobile-flutter && bash tool/bootstrap.sh
#
# 幂等：可重复运行；每次都会用仓库里的受管文件覆盖 flutter create 的模板产物。
set -euo pipefail

ORG="com.wuhannav"
PROJECT_NAME="wuhan_nav"

# 受管文件：由仓库维护，flutter create 后需还原，避免被模板覆盖。
MANAGED=(
  "lib"
  "test"
  "pubspec.yaml"
  "analysis_options.yaml"
  "README.md"
)

if ! command -v flutter >/dev/null 2>&1; then
  echo "[bootstrap] 未找到 flutter，请先安装 Flutter SDK（>=3.29）。" >&2
  exit 1
fi

echo "[bootstrap] Flutter 版本："
flutter --version | head -1

BACKUP_DIR="$(mktemp -d)"
echo "[bootstrap] 备份受管文件到 ${BACKUP_DIR}"
for path in "${MANAGED[@]}"; do
  if [ -e "$path" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$path")"
    cp -R "$path" "${BACKUP_DIR}/$(dirname "$path")/"
  fi
done

echo "[bootstrap] 生成 Android 平台层（仅 Android）..."
flutter create . \
  --platforms=android \
  --org "${ORG}" \
  --project-name "${PROJECT_NAME}" \
  --overwrite

echo "[bootstrap] 还原受管文件..."
for path in "${MANAGED[@]}"; do
  if [ -e "${BACKUP_DIR}/${path}" ]; then
    rm -rf "$path"
    cp -R "${BACKUP_DIR}/${path}" "$(dirname "$path")/"
  fi
done
rm -rf "${BACKUP_DIR}"

# 确保 main manifest 声明 INTERNET 权限（拉取瓦片需要；默认只在 debug manifest 里有）。
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ] && ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  echo "[bootstrap] 向 ${MANIFEST} 注入 INTERNET 权限..."
  awk '
    /<application/ && !done {
      print "    <uses-permission android:name=\"android.permission.INTERNET\"/>";
      done=1
    }
    { print }
  ' "$MANIFEST" > "${MANIFEST}.tmp" && mv "${MANIFEST}.tmp" "$MANIFEST"
fi

echo "[bootstrap] flutter pub get..."
flutter pub get

echo ""
echo "[bootstrap] 完成。接下来："
echo "  1) 连接 Android 真机/模拟器：flutter devices"
echo "  2) 运行（占位瓦片，无需 BFF）：flutter run"
echo "     或接自建瓦片："
echo "     flutter run --dart-define=TILES_URL_TEMPLATE=http://10.0.2.2:3000/tiles/{z}/{x}/{y}"
echo ""
echo "  提示：MapLibre 需要 minSdk>=21、Kotlin>=2.1.0、compileSdk>=34，"
echo "        当前 Flutter 模板默认已满足；若 gradle 报版本过低再按报错调整。"

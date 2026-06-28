#!/usr/bin/env bash
set -euo pipefail

app_dir="apps/mobile-flutter"

if [ ! -f "$app_dir/pubspec.yaml" ]; then
  echo "No Flutter project yet; $app_dir/pubspec.yaml will enable flutter analyze."
  exit 0
fi

cd "$app_dir"
flutter pub get
flutter analyze

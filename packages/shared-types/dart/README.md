# shared-types (Dart)

`packages/shared-types/src/index.ts` 的 Dart 绑定。Flutter 客户端通过 path 依赖引用，**不在 `apps/mobile-flutter` 内重复定义 DTO**。

坐标一律 WGS-84，`[lng, lat]` 顺序。

```yaml
# apps/mobile-flutter/pubspec.yaml
dependencies:
  shared_types:
    path: ../../packages/shared-types/dart
```

```dart
import 'package:shared_types/shared_types.dart';
```

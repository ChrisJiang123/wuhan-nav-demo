import 'package:flutter/material.dart';

/// 视觉 token（与 `.cursor/rules/00-project.mdc` 视觉小节一致）。
///
/// 颜色只服务路况与路线，不服务营销。改动请同步规则文件。
class AppColors {
  const AppColors._();

  /// 主品牌 / 当前路线 / 主按钮。
  static const Color brand = Color(0xFF1570EF);

  /// 强调 / 开始导航 / 成功 / 已上报。
  static const Color success = Color(0xFF12B76A);

  /// 警告 / 中度拥堵 / 施工。
  static const Color warning = Color(0xFFF79009);

  /// 危险 / 重度拥堵 / 事故 / 错误。
  static const Color danger = Color(0xFFD92D20);

  /// 白天底色。
  static const Color dayBackground = Color(0xFFF8FAFC);

  /// 夜间底色 / 底部面板。
  static const Color nightBackground = Color(0xFF0F172A);

  /// 次级 / 辅助文字。
  static const Color textSecondary = Color(0xFF475467);
  static const Color textTertiary = Color(0xFF98A2B3);
}

/// 动效时长：短促低弹性（180–240ms）。
class AppMotion {
  const AppMotion._();

  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 240);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      surface: AppColors.dayBackground,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.dayBackground,
    );
  }
}

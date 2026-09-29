import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

/// 圆角体系
class AppRadii {
  const AppRadii._();
  static const double s = 13;
  static const double m = 18;
  static const double l = 26;
  static const double sheet = 30;
  static const double pill = 999;
}

/// 阴影体系
class AppShadows {
  const AppShadows._();

  /// 卡片柔和阴影
  static List<BoxShadow> soft(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return <BoxShadow>[
        BoxShadow(
          color: Colors.black.withAlpha(130),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];
    }
    return <BoxShadow>[
      BoxShadow(
        color: const Color(0xFF0B0B16).withAlpha(10),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color(0xFF0B0B16).withAlpha(12),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// 主色按钮辉光
  static List<BoxShadow> brand() => <BoxShadow>[
        BoxShadow(
          color: AppColors.brand1.withAlpha(82),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// 侧边栏投影
  static List<BoxShadow> drawer() => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withAlpha(70),
          blurRadius: 44,
          offset: const Offset(14, 0),
        ),
      ];
}

/// 主题构建
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand1,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.bg,
      canvasColor: palette.bg,
      dividerColor: palette.line,
      splashColor: fade(palette.text, 0.05),
      highlightColor: fade(palette.text, 0.03),
      fontFamilyFallback: const <String>['PingFang SC', 'Heiti SC', 'Microsoft YaHei'],
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: Typography.blackMountainView.apply(
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
    );
  }
}

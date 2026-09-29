import 'package:flutter/material.dart';

/// 设计令牌：品牌色、渐变、功能色。
///
/// 与 UI 原型一一对应：主色 Indigo → Purple 渐变。
class AppColors {
  const AppColors._();

  /// 渐变色 1（Indigo）
  static const Color brand1 = Color(0xFF6366F1);

  /// 渐变色 2（Purple）
  static const Color brand2 = Color(0xFFA855F7);

  /// 渐变压深色（用于图标右下角）
  static const Color brand3 = Color(0xFF4C1D95);

  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFF43F5E);

  /// 品牌主渐变（按钮、选中态、强调元素）
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[brand1, brand2],
  );

  /// 危险操作渐变（左滑删除等）
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFB5A75), danger],
  );

  /// 主色淡底（用于浅色高亮块）
  static const LinearGradient brandSoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x246366F1), Color(0x1AA855F7)],
  );
}

/// 按透明度取色的小工具，避免使用已废弃的 withOpacity。
Color fade(Color color, double opacity) {
  final int a = (opacity.clamp(0.0, 1.0) * 255).round();
  return color.withAlpha(a);
}

/// 主色作为文字色时的取值：深色模式下需要更亮，否则看不清。
Color brandTextOn(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA5B4FC)
        : AppColors.brand1;

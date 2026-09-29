import 'package:flutter/material.dart';

/// 明暗两套界面配色，通过 [ThemeExtension] 挂到 ThemeData 上，
/// 组件里用 `context.palette` 读取，切换深浅色时自动过渡。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.bgTop,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.text2,
    required this.text3,
    required this.line,
    required this.line2,
    required this.nav,
    required this.mask,
  });

  /// 页面底色（渐变的下半部分）
  final Color bg;

  /// 页面底色（顶部，略亮，形成层次）
  final Color bgTop;

  /// 卡片 / 弹层表面
  final Color surface;

  /// 次级表面
  final Color surface2;

  /// 内嵌填充区（输入框、键位）
  final Color surface3;

  /// 主文字
  final Color text;

  /// 次要文字
  final Color text2;

  /// 三级文字 / 占位
  final Color text3;

  /// 分割线
  final Color line;

  /// 更明显的分割线（拖拽条、步骤条）
  final Color line2;

  /// 导航栏 / 底部栏（半透明玻璃）
  final Color nav;

  /// 遮罩
  final Color mask;

  static const AppPalette light = AppPalette(
    bg: Color(0xFFF5F5FA),
    bgTop: Color(0xFFEEEEF7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    surface3: Color(0xFFF2F2F8),
    text: Color(0xFF0B0B16),
    text2: Color(0xFF71718A),
    text3: Color(0xFFA5A5BC),
    line: Color(0x120B0B16),
    line2: Color(0x1F0B0B16),
    nav: Color(0xE6FAFAFF),
    mask: Color(0x6B0C0C18),
  );

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF08080D),
    bgTop: Color(0xFF0C0C14),
    surface: Color(0xFF14141C),
    surface2: Color(0xFF1B1B25),
    surface3: Color(0xFF22222E),
    text: Color(0xFFF6F6FB),
    text2: Color(0xFF8E8EA6),
    text3: Color(0xFF5E5E78),
    line: Color(0x14FFFFFF),
    line2: Color(0x24FFFFFF),
    nav: Color(0xE6101018),
    mask: Color(0x99000000),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? bgTop,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? text,
    Color? text2,
    Color? text3,
    Color? line,
    Color? line2,
    Color? nav,
    Color? mask,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      bgTop: bgTop ?? this.bgTop,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      nav: nav ?? this.nav,
      mask: mask ?? this.mask,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      mask: Color.lerp(mask, other.mask, t)!,
    );
  }
}

/// 快捷读取：`context.palette.surface`
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// 页面底色渐变
  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[palette.bgTop, palette.bg],
        stops: const <double>[0.0, 0.32],
      );
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// 玻璃拟态导航栏（顶部 / 弹层通用）
class GlassNavbar extends StatelessWidget {
  const GlassNavbar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.height = 48,
    this.blur = true,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Widget content = SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 76),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.35,
                    color: palette.text,
                  ),
                ),
              ),
            ),
          ),
          if (leading != null)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(child: leading),
            ),
          if (trailing != null)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(child: trailing),
            ),
        ],
      ),
    );

    if (!blur) {
      return ColoredBox(color: palette.nav, child: content);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(color: palette.nav, child: content),
      ),
    );
  }
}

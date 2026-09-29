import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// 主按钮：品牌渐变 + 辉光，按下轻微缩放。
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 50,
    this.expand = true,
    this.enabled = true,
    this.gradient,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final bool expand;
  final bool enabled;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && onTap != null;
    const Radius radius = Radius.circular(AppRadii.m - 2);

    return Opacity(
      opacity: active ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.brandGradient,
          borderRadius: const BorderRadius.all(radius),
          boxShadow: active ? AppShadows.brand() : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: const BorderRadius.all(radius),
            onTap: active ? onTap : null,
            child: SizedBox(
              height: height,
              width: expand ? double.infinity : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 次级按钮：浅底描边
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 50,
    this.expand = false,
    this.foreground,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final bool expand;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = foreground ?? palette.text;
    const Radius radius = Radius.circular(AppRadii.m - 2);

    return Material(
      color: palette.surface3,
      borderRadius: const BorderRadius.all(radius),
      child: InkWell(
        borderRadius: const BorderRadius.all(radius),
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: expand ? double.infinity : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 导航栏上的圆形/圆角图标按钮
class NavIconButton extends StatelessWidget {
  const NavIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.size = 20,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.s - 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.s - 1),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: size, color: color ?? palette.text),
        ),
      ),
    );
  }
}

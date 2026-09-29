import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// 轻提示：不打断当前操作，1.8 秒后自动消失。
void showAppToast(BuildContext context, String message, {bool success = true}) {
  final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  showAppToastOn(overlay, message, success: success);
}

/// 在已经拿到的 Overlay 上弹提示（用于 widget 即将被移除的场景，例如左滑删除后）。
void showAppToastOn(OverlayState overlay, String message, {bool success = true}) {
  late final OverlayEntry entry;
  bool removed = false;

  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (BuildContext ctx) => Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(ctx).padding.bottom + 92,
      child: IgnorePointer(
        child: Center(
          child: _ToastBubble(message: message, success: success),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Timer(const Duration(milliseconds: 1800), remove);
}

class _ToastBubble extends StatelessWidget {
  const _ToastBubble({required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: palette == AppPalette.dark
            ? const Color(0xE61B1B25)
            : const Color(0xE6121218),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(30)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            success ? Icons.check_rounded : Icons.error_outline_rounded,
            size: 16,
            color: success ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

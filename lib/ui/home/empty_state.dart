import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// 首次启动 / 工具清空后的引导页。
/// 注意：这里不放「新建工具」按钮，入口按设计只在侧边栏底部。
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: AppColors.brandSoftGradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.brand1.withAlpha(56)),
              ),
              child: const Icon(
                Icons.handyman_outlined,
                size: 40,
                color: AppColors.brand1,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppText.emptyTitle,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppText.emptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: palette.text2,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surface3,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.menu_rounded, size: 15, color: palette.text3),
                  const SizedBox(width: 7),
                  Text(
                    '左上角菜单打开侧边栏',
                    style: TextStyle(fontSize: 12.5, color: palette.text2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

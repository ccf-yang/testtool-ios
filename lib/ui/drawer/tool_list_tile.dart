import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tool.dart';
import '../../providers/tool_providers.dart';
import '../widgets/app_toast.dart';

/// 侧边栏里的一行工具。
/// - 点击：切换工具并收起侧边栏
/// - 左滑：删除（二次确认）
class ToolListTile extends ConsumerWidget {
  const ToolListTile({super.key, required this.tool});

  final Tool tool;

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('删除工具'),
        content: Text('确定要删除「${tool.displayName}」吗？此操作不可撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppText.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppText.delete),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final bool active = ref.watch(currentToolIdProvider) == tool.id;
    final Color activeColor = brandTextOn(context);

    // widget 可能在被移除后才弹提示，这里先把 Overlay 抓在手里
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Dismissible(
        key: ValueKey<String>('tool-${tool.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (DismissDirection _) => _confirmDelete(context),
        onDismissed: (DismissDirection _) {
          ref.read(toolListProvider.notifier).remove(tool.id);
          if (overlay != null) {
            showAppToastOn(overlay, '已删除「${tool.displayName}」');
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            gradient: AppColors.dangerGradient,
            borderRadius: BorderRadius.circular(AppRadii.s),
          ),
          child: const Text(
            AppText.delete,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.s),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.s),
            onTap: () {
              scaffold?.closeDrawer();
              ref.read(selectedToolIdProvider.notifier).select(tool.id);
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.s),
                gradient: active ? AppColors.brandSoftGradient : null,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      tool.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        letterSpacing: -0.2,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? activeColor : palette.text,
                      ),
                    ),
                  ),
                  if (active)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.brandGradient,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

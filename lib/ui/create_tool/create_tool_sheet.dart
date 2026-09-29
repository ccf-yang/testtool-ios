import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tool.dart';
import '../../providers/create_flow_providers.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_navbar.dart';
import '../widgets/step_indicator.dart';
import 'step_import.dart';
import 'step_preview.dart';
import 'step_requirement.dart';

/// 新建工具浮层：同一个 Sheet 内走完 需求 → 导入 → 预览 三步。
class CreateToolSheet extends ConsumerWidget {
  const CreateToolSheet({super.key});

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final Tool? tool = await ref.read(createFlowProvider.notifier).apply();
    if (!context.mounted) return;
    if (tool != null) {
      Navigator.of(context).pop(tool);
    } else {
      final String? error = ref.read(createFlowProvider).error;
      showAppToast(context, error ?? '保存失败', success: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final CreateFlowState flow = ref.watch(createFlowProvider);

    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboard = MediaQuery.of(context).viewInsets.bottom;
    final double height =
        math.min(screenHeight * 0.92, screenHeight - keyboard - 24);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        child: Column(
          children: <Widget>[
            // 拖拽条
            Container(
              margin: const EdgeInsets.only(top: 9),
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: palette.line2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            GlassNavbar(
              height: 52,
              blur: false,
              title: AppText.newTool,
              leading: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppText.cancel,
                  style: TextStyle(fontSize: 15.5, color: palette.text2),
                ),
              ),
              trailing: flow.step == CreateStep.preview
                  ? TextButton(
                      onPressed: () => _apply(context, ref),
                      child: Text(
                        '应用',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: brandTextOn(context),
                        ),
                      ),
                    )
                  : null,
            ),

            StepIndicator(current: flow.step.index),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (flow.step) {
                  CreateStep.requirement =>
                    const StepRequirement(key: ValueKey<String>('step-1')),
                  CreateStep.import =>
                    const StepImport(key: ValueKey<String>('step-2')),
                  CreateStep.preview =>
                    const StepPreview(key: ValueKey<String>('step-3')),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

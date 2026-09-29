import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/tool_content_parser.dart';
import '../../data/models/tool.dart';
import '../../providers/create_flow_providers.dart';
import '../widgets/app_toast.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tool_webview.dart';

/// 第 3 步：预览效果 → 应用并保存
class StepPreview extends ConsumerWidget {
  const StepPreview({super.key});

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
    final ParseResult? parsed = flow.parsed;

    if (parsed == null) {
      return Center(
        child: Text(
          '没有可预览的内容',
          style: TextStyle(fontSize: 14, color: palette.text2),
        ),
      );
    }

    final String displayName = flow.name.trim().isNotEmpty
        ? flow.name.trim()
        : (parsed.hasName ? parsed.name.trim() : AppText.unnamedTool);

    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.m),
              child: DecoratedBox(
                decoration: BoxDecoration(color: palette.bg),
                child: ToolWebView(html: parsed.html),
              ),
            ),
          ),
        ),
        if (parsed.warning != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text(
              parsed.warning!,
              style: TextStyle(fontSize: 11.5, color: palette.text3),
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          child: Column(
            children: <Widget>[
              Text(
                '将保存为「$displayName」',
                style: TextStyle(fontSize: 12.5, color: palette.text2),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: SoftButton(
                      label: AppText.backAction,
                      expand: true,
                      onTap: () =>
                          ref.read(createFlowProvider.notifier).toImport(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: GradientButton(
                      label: AppText.applyAction,
                      expand: true,
                      onTap: () => _apply(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

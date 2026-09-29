import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/create_flow_providers.dart';
import '../widgets/app_field.dart';
import '../widgets/gradient_button.dart';

/// 第 2 步：已复制提示词 → 粘贴大模型返回内容 → 预览
class StepImport extends ConsumerStatefulWidget {
  const StepImport({super.key});

  @override
  ConsumerState<StepImport> createState() => _StepImportState();
}

class _StepImportState extends ConsumerState<StepImport> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(
      text: ref.read(createFlowProvider).rawInput,
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _preview() {
    FocusScope.of(context).unfocus();
    ref.read(createFlowProvider.notifier).parseAndPreview();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final CreateFlowState flow = ref.watch(createFlowProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: <Widget>[
        // 已复制提示
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: AppColors.brandSoftGradient,
            borderRadius: BorderRadius.circular(AppRadii.m),
            border: Border.all(color: AppColors.brand1.withAlpha(56)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppText.promptCopied,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '打开大模型 App 粘贴发送，再把返回内容整体复制回来',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: palette.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const AppFieldLabel(AppText.pasteLabel),
        AppTextField(
          controller: _input,
          hint: AppText.pasteHint,
          minLines: 9,
          maxLines: 14,
          monospace: true,
          fontSize: 12.5,
          onChanged: (String v) =>
              ref.read(createFlowProvider.notifier).setRawInput(v),
        ),
        const SizedBox(height: 14),

        const AppHintCard(
          text: '支持 JSON（{"name":"…","html":"…"}）或纯 HTML，会自动识别；'
              '名称为空时取 JSON 里的 name。',
        ),

        if (flow.error != null) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.error_outline_rounded,
                    size: 15, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flow.error!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.danger,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),
        GradientButton(
          label: AppText.previewAction,
          icon: Icons.visibility_outlined,
          enabled: flow.canPreview,
          onTap: _preview,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () =>
                ref.read(createFlowProvider.notifier).toRequirement(),
            child: Text(
              '${AppText.back}上一步',
              style: TextStyle(fontSize: 14, color: palette.text2),
            ),
          ),
        ),
      ],
    );
  }
}

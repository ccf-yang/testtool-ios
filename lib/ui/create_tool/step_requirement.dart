import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/create_flow_providers.dart';
import '../../providers/template_providers.dart';
import '../widgets/app_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/gradient_button.dart';

/// 第 1 步：描述需求 → 生成提示词并复制
class StepRequirement extends ConsumerStatefulWidget {
  const StepRequirement({super.key});

  @override
  ConsumerState<StepRequirement> createState() => _StepRequirementState();
}

class _StepRequirementState extends ConsumerState<StepRequirement> {
  late final TextEditingController _requirement;
  late final TextEditingController _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final CreateFlowState flow = ref.read(createFlowProvider);
    _requirement = TextEditingController(text: flow.requirement);
    _name = TextEditingController(text: flow.name);
  }

  @override
  void dispose() {
    _requirement.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final bool ok =
        await ref.read(createFlowProvider.notifier).generateAndCopy();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) showAppToast(context, AppText.promptCopied);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final CreateFlowState flow = ref.watch(createFlowProvider);
    final String templateName =
        ref.watch(activeTemplateProvider)?.displayName ?? '（无模板）';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: <Widget>[
        const AppFieldLabel(AppText.requirementLabel),
        AppTextField(
          controller: _requirement,
          hint: AppText.requirementHint,
          minLines: 4,
          maxLines: 8,
          autofocus: true,
          onChanged: (String v) =>
              ref.read(createFlowProvider.notifier).setRequirement(v),
        ),
        const SizedBox(height: 18),

        const AppFieldLabel(AppText.nameLabel),
        AppTextField(
          controller: _name,
          hint: AppText.nameHint,
          onChanged: (String v) =>
              ref.read(createFlowProvider.notifier).setName(v),
        ),
        const SizedBox(height: 17),

        AppHintCard(
          text: '点击下方按钮，会按「$templateName」模板自动生成完整提示词并复制到剪贴板，'
              '再拿去任意大模型 App 粘贴发送。',
        ),

        if (flow.error != null) ...<Widget>[
          const SizedBox(height: 12),
          _ErrorText(text: flow.error!),
        ],

        const SizedBox(height: 18),
        GradientButton(
          label: AppText.generatePrompt,
          icon: Icons.auto_awesome_rounded,
          enabled: !_busy,
          onTap: _generate,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '当前模板可在「设置 → 提示词模板」中修改',
            style: TextStyle(fontSize: 11.5, color: palette.text3),
          ),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.danger,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

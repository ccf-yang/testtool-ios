import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/prompt_builder.dart';
import '../../data/models/prompt_template.dart';
import '../../providers/template_providers.dart';
import '../widgets/app_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_navbar.dart';
import '../widgets/gradient_button.dart';

/// 提示词模板编辑页（新建 / 修改）
class TemplateEditPage extends ConsumerStatefulWidget {
  const TemplateEditPage({super.key, this.templateId});

  /// null 表示新建
  final String? templateId;

  @override
  ConsumerState<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends ConsumerState<TemplateEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _body;
  late final bool _isNew;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final PromptTemplate? original = _find();
    _isNew = original == null;
    _name = TextEditingController(text: original?.name ?? '');
    _body = TextEditingController(text: original?.body ?? '');
    _isDefault = original?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    super.dispose();
  }

  PromptTemplate? _find() {
    final String? id = widget.templateId;
    if (id == null) return null;
    final List<PromptTemplate> list =
        ref.read(templateListProvider).valueOrNull ?? const <PromptTemplate>[];
    for (final PromptTemplate t in list) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final String body = _body.text;
    if (name.isEmpty) {
      showAppToast(context, '请填写模板名称', success: false);
      return;
    }
    if (body.trim().isEmpty) {
      showAppToast(context, '请填写模板正文', success: false);
      return;
    }

    final TemplateListNotifier notifier =
        ref.read(templateListProvider.notifier);
    final PromptTemplate? original = _find();

    if (original == null) {
      final PromptTemplate created =
          await notifier.add(name: name, body: body);
      if (_isDefault) await notifier.setDefault(created.id);
    } else {
      await notifier.updateTemplate(original.copyWith(name: name, body: body));
      if (_isDefault) await notifier.setDefault(original.id);
    }

    if (!mounted) return;
    showAppToast(context, '模板已保存');
    Navigator.of(context).maybePop();
  }

  Future<void> _delete() async {
    final PromptTemplate? original = _find();
    if (original == null) return;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除「${original.displayName}」吗？'),
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
    if (ok != true) return;

    await ref.read(templateListProvider.notifier).remove(original.id);
    if (!mounted) return;
    showAppToast(context, '模板已删除');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              GlassNavbar(
                title: _isNew ? '新建模板' : '编辑模板',
                leading: NavIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                trailing: TextButton(
                  onPressed: _save,
                  child: Text(
                    AppText.save,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: brandTextOn(context),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                  children: <Widget>[
                    const AppFieldLabel('模板名称'),
                    AppTextField(
                      controller: _name,
                      hint: '例如：标准 HTML 生成',
                    ),
                    const SizedBox(height: 20),
                    const AppFieldLabel('模板正文'),
                    AppTextField(
                      controller: _body,
                      hint: '在这里写提示词，用 ${PromptBuilder.requirementVar} 代表用户输入的需求',
                      minLines: 12,
                      maxLines: 24,
                      monospace: true,
                      fontSize: 12.5,
                    ),
                    const SizedBox(height: 16),
                    const AppHintCard(
                      text: '${PromptBuilder.requirementVar} 会在生成提示词时'
                          '自动替换成你在新建工具里填写的需求；'
                          '${PromptBuilder.toolNameVar} 会替换成工具名称。',
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppRadii.m),
                        border: Border.all(color: palette.line),
                      ),
                      child: SwitchListTile(
                        value: _isDefault,
                        onChanged: (bool v) => setState(() => _isDefault = v),
                        title: const Text(
                          '设为默认模板',
                          style: TextStyle(fontSize: 15.5),
                        ),
                        subtitle: Text(
                          '新建工具时优先使用',
                          style: TextStyle(fontSize: 12, color: palette.text2),
                        ),
                      ),
                    ),
                    if (!_isNew) ...<Widget>[
                      const SizedBox(height: 24),
                      GradientButton(
                        label: '删除此模板',
                        icon: Icons.delete_outline_rounded,
                        gradient: AppColors.dangerGradient,
                        onTap: _delete,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

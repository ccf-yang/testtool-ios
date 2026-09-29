import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/backup.dart';
import '../../data/models/prompt_template.dart';
import '../../data/models/tool.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/tool_repository.dart';
import '../../providers/storage_providers.dart';
import '../../providers/template_providers.dart';
import '../../providers/tool_providers.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_navbar.dart';
import '../widgets/gradient_button.dart';
import 'template_edit_page.dart';

/// 设置页：提示词模板管理 + 数据导出导入
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final List<PromptTemplate> templates =
        ref.watch(templateListProvider).valueOrNull ?? const <PromptTemplate>[];
    final PromptTemplate? active = ref.watch(activeTemplateProvider);
    final int toolsCount =
        ref.watch(toolListProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: palette.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              GlassNavbar(
                title: AppText.settingsTitle,
                leading: NavIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 20, bottom: 44),
                  children: <Widget>[
                    const _SectionTitle(AppText.templateSectionTitle),
                    _Card(
                      children: <Widget>[
                        for (final PromptTemplate t in templates)
                          _TemplateCell(
                            template: t,
                            isActive: active?.id == t.id,
                          ),
                        _AddTemplateCell(
                          onTap: () => _openEditor(context, null),
                        ),
                      ],
                    ),
                    const _SectionTitle(
                      AppText.dataSectionTitle,
                      top: 22,
                    ),
                    _Card(
                      children: <Widget>[
                        _ActionCell(
                          icon: Icons.ios_share_rounded,
                          label: '导出备份',
                          trailing: '$toolsCount 个工具 · ${templates.length} 个模板',
                          onTap: () => _export(context, ref),
                        ),
                        _ActionCell(
                          icon: Icons.file_download_outlined,
                          label: '导入备份',
                          onTap: () => _import(context, ref),
                        ),
                        _ActionCell(
                          icon: Icons.delete_outline_rounded,
                          label: '清空全部数据',
                          danger: true,
                          onTap: () => _clear(context, ref),
                        ),
                      ],
                    ),
                    const _SectionTitle('关于', top: 22),
                    const _Card(
                      children: <Widget>[
                        _ActionCell(
                          icon: Icons.info_outline_rounded,
                          label: '版本',
                          trailing: '1.0.0',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, String? templateId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => TemplateEditPage(templateId: templateId),
      ),
    );
  }

  // ------------------------------------------------------------ 导出

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    try {
      final ToolRepository repo = ref.read(toolRepositoryProvider);
      final List<Tool> index = await repo.loadIndex();
      final List<Tool> full = <Tool>[];
      for (final Tool t in index) {
        full.add(t.copyWith(html: await repo.loadHtml(t.id)));
      }
      final List<PromptTemplate> templates =
          await ref.read(templateListProvider.future);

      final DateTime now = DateTime.now();
      final BackupRepository backup = ref.read(backupRepositoryProvider);
      final String json = backup.encode(
        BackupPackage(exportedAt: now, tools: full, templates: templates),
      );
      final Uint8List bytes = Uint8List.fromList(utf8.encode(json));

      await Share.shareXFiles(
        <XFile>[
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: backup.fileName(now),
          ),
        ],
        subject: 'ToolBox 备份',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
      if (context.mounted) showAppToast(context, AppText.backupExported);
    } catch (e) {
      if (context.mounted) {
        showAppToast(context, '导出失败：$e', success: false);
      }
    }
  }

  // ------------------------------------------------------------ 导入

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final PlatformFile file = result.files.first;
      String? content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
      if (content == null) {
        if (context.mounted) {
          showAppToast(context, '无法读取所选文件', success: false);
        }
        return;
      }

      final BackupPackage package =
          ref.read(backupRepositoryProvider).decode(content);
      if (!context.mounted) return;

      final bool ok = await _confirm(
        context,
        title: '导入备份',
        content: '将导入 ${package.tools.length} 个工具、'
            '${package.templates.length} 个模板，追加到现有数据中。',
        confirmText: '导入',
      );
      if (!ok) return;

      for (final Tool t in package.tools) {
        await ref
            .read(toolListProvider.notifier)
            .add(name: t.name, html: t.html);
      }
      for (final PromptTemplate t in package.templates) {
        await ref
            .read(templateListProvider.notifier)
            .add(name: t.name, body: t.body);
      }
      if (context.mounted) showAppToast(context, AppText.backupImported);
    } on FormatException catch (e) {
      if (context.mounted) showAppToast(context, e.message, success: false);
    } catch (e) {
      if (context.mounted) {
        showAppToast(context, '导入失败：$e', success: false);
      }
    }
  }

  // ------------------------------------------------------------ 清空

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final bool ok = await _confirm(
      context,
      title: '清空全部数据',
      content: '将删除所有工具和自定义模板，此操作不可撤销。',
      confirmText: '清空',
    );
    if (!ok) return;
    await ref.read(toolListProvider.notifier).clear();
    if (context.mounted) showAppToast(context, '已清空全部工具');
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppText.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

// ------------------------------------------------------------ 小组件

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.top = 0});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, top, 22, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: palette.text3,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: palette.line),
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _TemplateCell extends ConsumerWidget {
  const _TemplateCell({required this.template, required this.isActive});

  final PromptTemplate template;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    return _Row(
      onTap: () {
        ref.read(activeTemplateIdProvider.notifier).select(template.id);
        showAppToast(context, '已切换为「${template.displayName}」');
      },
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              template.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                letterSpacing: -0.2,
                color: palette.text,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (template.isDefault) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppColors.brandSoftGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '默认',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: brandTextOn(context),
                ),
              ),
            ),
          ],
          if (isActive) ...<Widget>[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded,
                size: 18, color: brandTextOn(context)),
          ],
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: palette.text3),
            splashRadius: 18,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext _) =>
                    TemplateEditPage(templateId: template.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTemplateCell extends StatelessWidget {
  const _AddTemplateCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Row(
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.add_rounded, size: 17, color: brandTextOn(context)),
            const SizedBox(width: 6),
            Text(
              '新建模板',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: brandTextOn(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = danger ? AppColors.danger : palette.text;

    return _Row(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: danger ? AppColors.danger : palette.text2),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15.5, color: color, letterSpacing: -0.2),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(fontSize: 13, color: palette.text2),
            ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 20, color: palette.text3),
        ],
      ),
    );
  }
}

/// 列表行通用外壳（带分割线）
class _Row extends StatelessWidget {
  const _Row({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: palette.line),
      ],
    );
  }
}

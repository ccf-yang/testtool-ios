import 'dart:convert';

import '../app_paths.dart';
import '../file_utils.dart';
import '../models/prompt_template.dart';

/// 提示词模板持久化。
class TemplateRepository {
  TemplateRepository(this.paths);

  final AppPaths paths;

  /// 读取模板列表；文件不存在返回空列表（由上层决定是否写入内置默认模板）
  Future<List<PromptTemplate>> load() async {
    final String? raw = await readStringFileOrNull(paths.templatesFile);
    if (raw == null || raw.trim().isEmpty) return <PromptTemplate>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <PromptTemplate>[];
      final List<PromptTemplate> list = <PromptTemplate>[];
      for (final Object? item in decoded) {
        if (item is Map) {
          final PromptTemplate tpl =
              PromptTemplate.fromJson(Map<String, dynamic>.from(item));
          if (tpl.id.isNotEmpty) list.add(tpl);
        }
      }
      return list;
    } catch (_) {
      return <PromptTemplate>[];
    }
  }

  /// 写入模板列表
  Future<void> save(List<PromptTemplate> templates) async {
    await paths.ensure();
    await writeJsonFile(
      paths.templatesFile,
      templates.map((PromptTemplate t) => t.toJson()).toList(),
    );
  }
}

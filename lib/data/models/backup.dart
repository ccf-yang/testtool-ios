import 'prompt_template.dart';
import 'tool.dart';

/// 备份文件结构（导出/导入共用）。
///
/// schema 用于将来兼容旧备份；解析时校验版本。
class BackupPackage {
  const BackupPackage({
    required this.exportedAt,
    required this.tools,
    required this.templates,
    this.schema = currentSchema,
  });

  /// 当前备份格式版本
  static const int currentSchema = 1;

  final int schema;
  final DateTime exportedAt;

  /// 含 html 的完整工具列表
  final List<Tool> tools;
  final List<PromptTemplate> templates;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schema': schema,
        'exportedAt': exportedAt.toIso8601String(),
        'tools': tools.map((Tool t) => t.toFullJson()).toList(),
        'templates': templates.map((PromptTemplate t) => t.toJson()).toList(),
      };

  /// 解析备份内容，格式不合法时抛 [FormatException]
  factory BackupPackage.fromJson(Map<String, dynamic> json) {
    final Object? rawSchema = json['schema'];
    final int schema = rawSchema is num ? rawSchema.toInt() : -1;
    if (schema < 1) {
      throw const FormatException('备份文件缺少 schema 字段，可能不是有效的备份');
    }
    if (schema > currentSchema) {
      throw FormatException('备份版本($schema)高于当前 App 支持的版本($currentSchema)，请升级 App');
    }

    final List<Tool> tools = <Tool>[];
    final Object? rawTools = json['tools'];
    if (rawTools is List) {
      for (final Object? item in rawTools) {
        if (item is Map) {
          tools.add(Tool.fromFullJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final List<PromptTemplate> templates = <PromptTemplate>[];
    final Object? rawTemplates = json['templates'];
    if (rawTemplates is List) {
      for (final Object? item in rawTemplates) {
        if (item is Map) {
          templates.add(
            PromptTemplate.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return BackupPackage(
      schema: schema,
      exportedAt:
          DateTime.tryParse((json['exportedAt'] as String?) ?? '') ?? DateTime.now(),
      tools: tools,
      templates: templates,
    );
  }
}

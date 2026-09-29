import '../../core/constants.dart';

/// 工具模型。
///
/// 注意：`index.json` 里**不写 html**（避免列表加载时解析大字符串），
/// 正文单独存在 `tools/<id>.html`，需要时才载入。
class Tool {
  const Tool({
    required this.id,
    required this.name,
    required this.order,
    required this.createdAt,
    this.html = '',
  });

  final String id;
  final String name;

  /// 排序权重，越小越靠前
  final int order;
  final DateTime createdAt;

  /// HTML 正文（列表态为空字符串）
  final String html;

  /// 展示用名称（空名兜底）
  String get displayName =>
      name.trim().isEmpty ? AppText.unnamedTool : name.trim();

  bool get hasHtml => html.trim().isNotEmpty;

  Tool copyWith({
    String? id,
    String? name,
    int? order,
    DateTime? createdAt,
    String? html,
  }) {
    return Tool(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      html: html ?? this.html,
    );
  }

  /// 写入 index.json（不含 html）
  Map<String, dynamic> toIndexJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Tool.fromIndexJson(Map<String, dynamic> json, {String html = ''}) {
    return Tool(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      html: html,
    );
  }

  /// 写入备份文件（含 html）
  Map<String, dynamic> toFullJson() => <String, dynamic>{
        ...toIndexJson(),
        'html': html,
      };

  factory Tool.fromFullJson(Map<String, dynamic> json) => Tool.fromIndexJson(
        json,
        html: (json['html'] as String?) ?? '',
      );

  @override
  String toString() => 'Tool($id, $name, order=$order)';
}

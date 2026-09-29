/// 提示词模板。正文里用 `{{requirement}}` 占位，生成时替换为用户输入的需求。
class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.name,
    required this.body,
    this.isDefault = false,
  });

  final String id;
  final String name;

  /// 模板正文，含 {{requirement}} / {{tool_name}} 占位符
  final String body;

  /// 是否为默认模板（新建工具时优先使用）
  final bool isDefault;

  String get displayName => name.trim().isEmpty ? '未命名模板' : name.trim();

  PromptTemplate copyWith({
    String? id,
    String? name,
    String? body,
    bool? isDefault,
  }) {
    return PromptTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      body: body ?? this.body,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'body': body,
        'isDefault': isDefault,
      };

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }

  @override
  String toString() => 'PromptTemplate($id, $name, default=$isDefault)';
}

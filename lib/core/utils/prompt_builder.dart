/// 提示词拼装：把模板里的占位符替换成实际内容。
///
/// 可用占位符：
/// - `{{requirement}}` 用户填写的需求（必需）
/// - `{{tool_name}}`   用户填写的工具名称（可选）
class PromptBuilder {
  const PromptBuilder._();

  static const String requirementVar = '{{requirement}}';
  static const String toolNameVar = '{{tool_name}}';

  /// 需求非空才允许生成
  static bool canGenerate(String requirement) => requirement.trim().isNotEmpty;

  /// 渲染提示词
  static String build({
    required String templateBody,
    required String requirement,
    String toolName = '',
  }) {
    final String req = requirement.trim();
    final String name = toolName.trim();
    return templateBody
        .replaceAll(requirementVar, req)
        .replaceAll(toolNameVar, name);
  }
}

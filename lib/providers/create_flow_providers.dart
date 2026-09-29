import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/prompt_builder.dart';
import '../core/utils/tool_content_parser.dart';
import '../data/models/prompt_template.dart';
import '../data/models/tool.dart';
import 'template_providers.dart';
import 'tool_providers.dart';

/// 新建工具的三个步骤
enum CreateStep {
  /// ① 描述需求
  requirement,

  /// ② 粘贴大模型返回内容
  import,

  /// ③ 预览 → 应用
  preview,
}

/// 新建流程状态机
class CreateFlowState {
  const CreateFlowState({
    this.step = CreateStep.requirement,
    this.requirement = '',
    this.name = '',
    this.rawInput = '',
    this.parsed,
    this.error,
  });

  final CreateStep step;
  final String requirement;
  final String name;
  final String rawInput;
  final ParseResult? parsed;
  final String? error;

  bool get canPreview => rawInput.trim().isNotEmpty;

  CreateFlowState copyWith({
    CreateStep? step,
    String? requirement,
    String? name,
    String? rawInput,
    ParseResult? parsed,
    String? error,
    bool clearParsed = false,
    bool clearError = false,
  }) {
    return CreateFlowState(
      step: step ?? this.step,
      requirement: requirement ?? this.requirement,
      name: name ?? this.name,
      rawInput: rawInput ?? this.rawInput,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CreateFlowNotifier extends Notifier<CreateFlowState> {
  @override
  CreateFlowState build() => const CreateFlowState();

  void setRequirement(String value) {
    state = state.copyWith(requirement: value, clearError: true);
  }

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  void setRawInput(String value) {
    state = state.copyWith(
      rawInput: value,
      clearError: true,
      clearParsed: true,
    );
  }

  /// 回到第一步
  void toRequirement() =>
      state = state.copyWith(step: CreateStep.requirement, clearError: true);

  /// 回到第二步
  void toImport() =>
      state = state.copyWith(step: CreateStep.import, clearError: true);

  /// 用当前选中的模板渲染提示词并写入剪贴板，成功后进入第二步
  Future<bool> generateAndCopy() async {
    final PromptTemplate? template = ref.read(activeTemplateProvider);
    if (template == null || template.body.trim().isEmpty) {
      state = state.copyWith(error: '还没有可用的提示词模板，请先到「设置」里添加');
      return false;
    }
    if (!PromptBuilder.canGenerate(state.requirement)) {
      state = state.copyWith(error: '请先描述你的需求');
      return false;
    }

    final String prompt = PromptBuilder.build(
      templateBody: template.body,
      requirement: state.requirement,
      toolName: state.name,
    );
    await Clipboard.setData(ClipboardData(text: prompt));
    state = state.copyWith(step: CreateStep.import, clearError: true);
    return true;
  }

  /// 解析粘贴内容，成功则进入预览
  bool parseAndPreview() {
    try {
      final ParseResult result = ToolContentParser.parse(
        state.rawInput,
        fallbackName: state.name.trim(),
      );
      state = state.copyWith(
        parsed: result,
        step: CreateStep.preview,
        clearError: true,
      );
      return true;
    } on ToolParseException catch (e) {
      state = state.copyWith(error: e.message, clearParsed: true);
      return false;
    } catch (e) {
      state = state.copyWith(error: '解析失败：$e', clearParsed: true);
      return false;
    }
  }

  /// 落库：写文件 + 刷新列表 + 选中新工具
  Future<Tool?> apply() async {
    final ParseResult? parsed = state.parsed;
    if (parsed == null) {
      state = state.copyWith(error: '请先粘贴内容并预览');
      return null;
    }

    final String name = state.name.trim().isNotEmpty
        ? state.name.trim()
        : (parsed.hasName ? parsed.name.trim() : '');

    final Tool tool = await ref.read(toolListProvider.notifier).add(
          name: name,
          html: parsed.html,
        );
    ref.read(selectedToolIdProvider.notifier).select(tool.id);
    return tool;
  }

  /// 关闭浮层时重置
  void reset() => state = const CreateFlowState();
}

final createFlowProvider =
    NotifierProvider<CreateFlowNotifier, CreateFlowState>(
  CreateFlowNotifier.new,
);

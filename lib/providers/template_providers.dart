import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/default_templates.dart';
import '../core/utils/id_gen.dart';
import '../data/models/prompt_template.dart';
import '../data/repositories/template_repository.dart';
import 'storage_providers.dart';

/// 提示词模板列表：加载 / 新增 / 修改 / 删除 / 设为默认。
class TemplateListNotifier extends AsyncNotifier<List<PromptTemplate>> {
  TemplateRepository get _repo => ref.read(templateRepositoryProvider);

  @override
  Future<List<PromptTemplate>> build() async {
    List<PromptTemplate> list = await _repo.load();
    if (list.isEmpty) {
      // 首次启动：把内置模板写入本地
      list = await loadDefaultTemplates();
      await _repo.save(list);
    }
    return _normalizeDefault(list);
  }

  List<PromptTemplate> get _current =>
      state.valueOrNull ?? const <PromptTemplate>[];

  /// 保证「有且只有一个默认模板」，没有就把第一个设为默认
  List<PromptTemplate> _normalizeDefault(List<PromptTemplate> list) {
    if (list.isEmpty) return list;
    final int idx = list.indexWhere((PromptTemplate t) => t.isDefault);
    if (idx == 0) return list;
    final List<PromptTemplate> next = <PromptTemplate>[];
    for (int i = 0; i < list.length; i++) {
      next.add(list[i].copyWith(isDefault: i == 0));
    }
    return next;
  }

  Future<void> _commit(List<PromptTemplate> list) async {
    await _repo.save(list);
    state = AsyncData<List<PromptTemplate>>(list);
  }

  Future<PromptTemplate> add({
    required String name,
    required String body,
  }) async {
    final PromptTemplate tpl = PromptTemplate(
      id: newId(),
      name: name.trim(),
      body: body,
      isDefault: _current.isEmpty,
    );
    await _commit(<PromptTemplate>[..._current, tpl]);
    return tpl;
  }

  /// 修改已有模板（名字不用 `update`，避免与 AsyncNotifierBase.update 冲突）
  Future<void> updateTemplate(PromptTemplate template) async {
    final List<PromptTemplate> next = _current
        .map((PromptTemplate t) => t.id == template.id ? template : t)
        .toList(growable: false);
    await _commit(_normalizeDefault(next));
  }

  Future<void> remove(String id) async {
    final List<PromptTemplate> next =
        _current.where((PromptTemplate t) => t.id != id).toList(growable: false);
    await _commit(_normalizeDefault(next));
    if (ref.read(activeTemplateIdProvider) == id) {
      ref.read(activeTemplateIdProvider.notifier).select(null);
    }
  }

  Future<void> setDefault(String id) async {
    final List<PromptTemplate> next = _current
        .map((PromptTemplate t) => t.copyWith(isDefault: t.id == id))
        .toList(growable: false);
    await _commit(next);
  }
}

final templateListProvider =
    AsyncNotifierProvider<TemplateListNotifier, List<PromptTemplate>>(
  TemplateListNotifier.new,
);

/// 手动指定的当前模板 ID（null = 用默认模板）
class ActiveTemplateNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final activeTemplateIdProvider =
    NotifierProvider<ActiveTemplateNotifier, String?>(
  ActiveTemplateNotifier.new,
);

/// 实际生效的模板：手动指定 > 默认 > 第一个
final activeTemplateProvider = Provider<PromptTemplate?>((ref) {
  final List<PromptTemplate> list =
      ref.watch(templateListProvider).valueOrNull ?? const <PromptTemplate>[];
  if (list.isEmpty) return null;

  final String? id = ref.watch(activeTemplateIdProvider);
  if (id != null) {
    for (final PromptTemplate t in list) {
      if (t.id == id) return t;
    }
  }
  for (final PromptTemplate t in list) {
    if (t.isDefault) return t;
  }
  return list.first;
});

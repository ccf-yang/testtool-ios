import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/id_gen.dart';
import '../data/models/tool.dart';
import '../data/repositories/tool_repository.dart';
import 'storage_providers.dart';

/// 工具列表：加载 / 新增 / 删除 / 清空。
class ToolListNotifier extends AsyncNotifier<List<Tool>> {
  ToolRepository get _repo => ref.read(toolRepositoryProvider);

  @override
  Future<List<Tool>> build() async {
    final List<Tool> tools = await _repo.loadIndex();
    tools.sort((Tool a, Tool b) => a.order.compareTo(b.order));
    return tools;
  }

  List<Tool> get _current => state.valueOrNull ?? const <Tool>[];

  /// 新增工具：先写正文文件，再更新索引，最后刷新内存状态
  Future<Tool> add({required String name, required String html}) async {
    final List<Tool> current = _current;
    final Tool tool = Tool(
      id: newId(),
      name: name.trim(),
      order: _repo.nextOrder(current),
      createdAt: DateTime.now(),
      html: html,
    );
    await _repo.writeHtml(tool.id, html);
    final List<Tool> next = <Tool>[...current, tool];
    await _repo.saveIndex(next);
    state = AsyncData<List<Tool>>(next);
    return tool;
  }

  /// 删除工具（正文文件 + 索引）
  Future<void> remove(String id) async {
    final List<Tool> next =
        _current.where((Tool t) => t.id != id).toList(growable: false);
    await _repo.deleteHtml(id);
    await _repo.saveIndex(next);
    state = AsyncData<List<Tool>>(next);
    if (ref.read(selectedToolIdProvider) == id) {
      ref.read(selectedToolIdProvider.notifier).select(null);
    }
  }

  /// 清空全部工具
  Future<void> clear() async {
    await _repo.clearAll();
    state = const AsyncData<List<Tool>>(<Tool>[]);
    ref.read(selectedToolIdProvider.notifier).select(null);
  }

  /// 从磁盘重新加载
  Future<void> reload() async {
    state = const AsyncLoading<List<Tool>>();
    state = await AsyncValue.guard(build);
  }
}

final toolListProvider =
    AsyncNotifierProvider<ToolListNotifier, List<Tool>>(ToolListNotifier.new);

/// 当前选中的工具 ID（null = 还没手动选过）
class SelectedToolNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedToolIdProvider =
    NotifierProvider<SelectedToolNotifier, String?>(SelectedToolNotifier.new);

/// 实际生效的工具 ID：手动选中的若仍存在则用它，否则回落到第一个。
/// 纯派生、无副作用，所以启动时天然满足「默认展示第一个工具」。
final currentToolIdProvider = Provider<String?>((ref) {
  final List<Tool> tools =
      ref.watch(toolListProvider).valueOrNull ?? const <Tool>[];
  if (tools.isEmpty) return null;

  final String? selected = ref.watch(selectedToolIdProvider);
  if (selected != null && tools.any((Tool t) => t.id == selected)) {
    return selected;
  }
  return tools.first.id;
});

/// 当前工具对象（含名称，不含正文）
final currentToolProvider = Provider<Tool?>((ref) {
  final String? id = ref.watch(currentToolIdProvider);
  if (id == null) return null;
  final List<Tool> tools =
      ref.watch(toolListProvider).valueOrNull ?? const <Tool>[];
  for (final Tool t in tools) {
    if (t.id == id) return t;
  }
  return null;
});

/// 列表指纹：新增 / 删除 / 重排后变化，用来让缓存的正文失效
final toolListRevisionProvider = Provider<String>((ref) {
  final List<Tool> tools =
      ref.watch(toolListProvider).valueOrNull ?? const <Tool>[];
  return tools.map((Tool t) => '${t.id}:${t.order}').join(',');
});

/// 某个工具的 HTML 正文
final toolHtmlProvider = FutureProvider.family<String, String>(
  (ref, String id) async {
    final AsyncValue<List<Tool>> tools = ref.watch(toolListProvider);
    if (!tools.hasValue) return '';
    // 列表变了就重新读盘，保证新导入的工具立刻能渲染
    ref.watch(toolListRevisionProvider);
    return ref.read(toolRepositoryProvider).loadHtml(id);
  },
);

/// 当前工具正文的异步状态（空列表时直接给空串，不发 IO）
final currentToolHtmlProvider = Provider<AsyncValue<String>>((ref) {
  final String? id = ref.watch(currentToolIdProvider);
  if (id == null) return const AsyncData<String>('');
  return ref.watch(toolHtmlProvider(id));
});

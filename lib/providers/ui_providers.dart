import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/tool.dart';
import 'tool_providers.dart';

/// 侧边栏搜索关键词
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// 过滤后的工具列表（按名称模糊匹配）
final filteredToolsProvider = Provider<List<Tool>>((ref) {
  final List<Tool> tools =
      ref.watch(toolListProvider).valueOrNull ?? const <Tool>[];
  final String query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return tools;
  return tools
      .where((Tool t) => t.displayName.toLowerCase().contains(query))
      .toList(growable: false);
});

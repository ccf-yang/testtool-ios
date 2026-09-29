import 'dart:convert';

import '../../core/constants.dart';
import '../app_paths.dart';
import '../file_utils.dart';
import '../models/tool.dart';

/// 工具持久化。
///
/// 存储策略：
/// - `index.json`      只存元信息（id / name / order / createdAt），启动时秒开；
/// - `tools/<id>.html` 每个工具的正文单独一个文件，用到才读。
class ToolRepository {
  ToolRepository(this.paths);

  final AppPaths paths;

  /// 读取工具列表（不含正文）
  Future<List<Tool>> loadIndex() async {
    final String? raw = await readStringFileOrNull(paths.indexFile);
    if (raw == null || raw.trim().isEmpty) return <Tool>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <Tool>[];
      final List<Tool> tools = <Tool>[];
      for (final Object? item in decoded) {
        if (item is Map) {
          final Tool tool = Tool.fromIndexJson(Map<String, dynamic>.from(item));
          if (tool.id.isNotEmpty) tools.add(tool);
        }
      }
      tools.sort((Tool a, Tool b) => a.order.compareTo(b.order));
      return tools;
    } catch (_) {
      // index 损坏时不阻塞启动，返回空列表
      return <Tool>[];
    }
  }

  /// 写入工具列表（不含正文）
  Future<void> saveIndex(List<Tool> tools) async {
    await paths.ensure();
    await writeJsonFile(
      paths.indexFile,
      tools.map((Tool t) => t.toIndexJson()).toList(),
    );
  }

  /// 读取某个工具的 HTML 正文，不存在返回空串
  Future<String> loadHtml(String id) async {
    final String? raw = await readStringFileOrNull(paths.toolFile(id));
    return raw ?? '';
  }

  /// 写入某个工具的 HTML 正文
  Future<void> writeHtml(String id, String html) async {
    await paths.ensure();
    await writeStringFile(paths.toolFile(id), html);
  }

  /// 删除某个工具的正文文件
  Future<void> deleteHtml(String id) async {
    try {
      final file = paths.toolFile(id);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 删除失败不影响索引更新
    }
  }

  /// 清空全部工具数据
  Future<void> clearAll() async {
    try {
      if (await paths.toolsDir.exists()) {
        await paths.toolsDir.delete(recursive: true);
      }
      if (await paths.indexFile.exists()) {
        await paths.indexFile.delete();
      }
    } catch (_) {
      // 忽略
    }
    await paths.ensure();
  }

  /// 生成一个不与现有工具冲突的排序值
  int nextOrder(List<Tool> tools) {
    if (tools.isEmpty) return 0;
    int max = tools.first.order;
    for (final Tool t in tools) {
      if (t.order > max) max = t.order;
    }
    return max + 1;
  }

  String get storageHint =>
      '数据目录：${paths.root.path}（${AppDirs.indexFile} + ${AppDirs.tools}/）';
}

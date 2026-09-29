import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

/// 应用本地目录与文件路径的统一入口。
///
/// 测试时可以直接 `AppPaths(Directory.systemTemp.createTempSync())` 构造，
/// 不依赖 path_provider。
class AppPaths {
  AppPaths(this.root);

  /// 数据根目录：`<Documents>/toolbox`
  final Directory root;

  /// 工具 HTML 目录
  Directory get toolsDir => Directory(p.join(root.path, AppDirs.tools));

  /// 工具索引文件
  File get indexFile => File(p.join(root.path, AppDirs.indexFile));

  /// 模板文件
  File get templatesFile => File(p.join(root.path, AppDirs.templatesFile));

  /// 单个工具的 HTML 文件
  File toolFile(String id) =>
      File(p.join(toolsDir.path, '$id${AppDirs.htmlExt}'));

  /// 保证目录存在
  Future<void> ensure() async {
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    if (!await toolsDir.exists()) {
      await toolsDir.create(recursive: true);
    }
  }

  /// 生产环境使用：解析系统文档目录
  static Future<AppPaths> resolve() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final AppPaths paths = AppPaths(Directory(p.join(docs.path, AppDirs.root)));
    await paths.ensure();
    return paths;
  }
}

import 'dart:convert';

import '../models/backup.dart';

/// 备份编解码（纯逻辑，不碰文件系统，方便单测）。
///
/// 文件的选择与分享由 UI 层负责（file_picker / share_plus）。
class BackupRepository {
  const BackupRepository();

  /// 把备份包编码成 JSON 文本
  String encode(BackupPackage package) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(package.toJson());
  }

  /// 解析备份文本；格式不对时抛 [FormatException]
  BackupPackage decode(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('备份文件格式不正确，应为 JSON 对象');
    }
    return BackupPackage.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// 生成备份文件名，如 toolbox-backup-20250101-120000.json
  String fileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    final String stamp = '${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return 'toolbox-backup-$stamp.json';
  }
}

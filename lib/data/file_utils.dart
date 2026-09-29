import 'dart:convert';
import 'dart:io';

/// 原子写文件：先写临时文件再改名，避免写一半崩溃导致文件损坏。
Future<void> writeStringFile(File file, String content) async {
  final File tmp = File('${file.path}.tmp');
  await tmp.writeAsString(content, flush: true);
  final File target = File(file.path);
  if (await target.exists()) {
    await target.delete();
  }
  await tmp.rename(target.path);
}

/// 原子写入 JSON（带缩进，便于用户直接查看备份文件）。
Future<void> writeJsonFile(File file, Object? value) async {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  await writeStringFile(file, encoder.convert(value));
}

/// 安全读取文本，文件不存在或读取失败都返回 null。
Future<String?> readStringFileOrNull(File file) async {
  try {
    if (!await file.exists()) return null;
    return await file.readAsString();
  } catch (_) {
    return null;
  }
}

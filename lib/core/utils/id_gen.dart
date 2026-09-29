import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// 生成工具 / 模板的唯一 ID（32 位无连字符字符串，可直接做文件名）。
String newId() => _uuid.v4().replaceAll('-', '');

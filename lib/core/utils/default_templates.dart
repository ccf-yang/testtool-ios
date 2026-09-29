import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../data/models/prompt_template.dart';
import '../constants.dart';
import 'id_gen.dart';

/// 从 assets 读取内置默认模板；读取失败时回退到一份最小可用模板，
/// 保证首次启动永远有模板可用。
Future<List<PromptTemplate>> loadDefaultTemplates() async {
  try {
    final String raw = await rootBundle.loadString(
      AppDirs.defaultTemplatesAsset,
    );
    final Object? decoded = jsonDecode(raw);
    if (decoded is List) {
      final List<PromptTemplate> list = <PromptTemplate>[];
      int index = 0;
      for (final Object? item in decoded) {
        if (item is! Map) continue;
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        final String body = (map['body'] as String?) ?? '';
        if (body.trim().isEmpty) continue;
        list.add(
          PromptTemplate(
            id: newId(),
            name: (map['name'] as String?) ?? '模板 ${index + 1}',
            body: body,
            isDefault: (map['isDefault'] as bool?) ?? index == 0,
          ),
        );
        index++;
      }
      if (list.isNotEmpty) return list;
    }
  } catch (_) {
    // 落到下面的兜底
  }
  return <PromptTemplate>[_fallbackTemplate()];
}

PromptTemplate _fallbackTemplate() => PromptTemplate(
      id: newId(),
      name: '标准 HTML 生成',
      isDefault: true,
      body: '请根据下面的需求生成一个 iOS 移动端工具页面。\n\n'
          '【需求】\n{{requirement}}\n\n'
          '【输出要求】\n只返回一个 Markdown 代码块（围栏语言标记为 json），'
          '代码块内是如下 JSON 对象，代码块外不要任何解释：\n'
          '```json\n'
          '{\n  "name": "工具名称",\n  "html": "完整的单文件 HTML 字符串"\n}\n'
          '```\n'
          '注意：JSON 字符串内的双引号和反斜杠需正确转义（正则、换行等反斜杠双写），'
          '避免转义错误导致解析失败。\n\n'
          '【HTML 规范】\n'
          '1. 单文件自包含，CSS 与 JS 内联；\n'
          '2. 含 viewport meta，宽度 100%，无横向滚动；\n'
          '3. 适配 prefers-color-scheme 深浅色；\n'
          '4. 按钮不小于 44px，底部预留安全区。',
    );

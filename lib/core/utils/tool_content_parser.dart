import 'dart:convert';

import '../constants.dart';

/// 解析失败时抛出，UI 直接把 message 显示给用户。
class ToolParseException implements Exception {
  const ToolParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 命中哪种解析方式
enum ParseMode {
  /// 大模型按约定返回了 JSON
  json,

  /// 直接就是一段 HTML
  html,
}

/// 解析结果
class ParseResult {
  const ParseResult({
    required this.mode,
    required this.name,
    required this.html,
    this.warning,
  });

  final ParseMode mode;

  /// 从 JSON 里读到的名称（可能为空，由用户填写的名称兜底）
  final String name;
  final String html;

  /// 非致命提示，例如「未识别到 JSON，已按纯 HTML 导入」
  final String? warning;

  bool get hasName => name.trim().isNotEmpty;
}

/// 把大模型返回的原文变成可渲染的 HTML。
///
/// 容错优先级：
/// 1. 剥掉 Markdown 代码块围栏；
/// 2. 尝试 JSON 解析，从 name/html/content/code 等字段里取正文；
/// 3. 都不行就整段当作纯 HTML 用。
class ToolContentParser {
  const ToolContentParser._();

  /// 可能是 HTML 字段的键名（兼容大模型乱起名）
  static const List<String> _htmlKeys = <String>[
    'html',
    'content',
    'code',
    'body',
    'source',
    'result',
  ];

  /// 可能是名称的键名
  static const List<String> _nameKeys = <String>['name', 'title', 'tool_name'];

  /// 形如 `<div` / `</div` / `<!DOCTYPE` 的标签特征
  static final RegExp _tagPattern = RegExp(r'<\s*[a-zA-Z!/]');

  static ParseResult parse(String raw, {String fallbackName = ''}) {
    final String text = _stripCodeFence(raw).trim();
    if (text.isEmpty) {
      throw const ToolParseException('内容为空，请先粘贴大模型返回的结果');
    }
    if (text.length > AppLimits.maxHtmlChars) {
      throw const ToolParseException('内容过大，请检查是否粘贴了无关内容');
    }

    final Object? decoded = _tryDecodeJson(text);
    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      final String? html = _pickString(map, _htmlKeys);
      if (html != null && html.trim().isNotEmpty) {
        _assertLooksLikeHtml(html);
        return ParseResult(
          mode: ParseMode.json,
          name: _pickString(map, _nameKeys) ?? fallbackName,
          html: html.trim(),
        );
      }
    } else if (decoded is String && decoded.trim().isNotEmpty) {
      // 大模型把 HTML 当成一个 JSON 字符串返回了
      _assertLooksLikeHtml(decoded);
      return ParseResult(
        mode: ParseMode.json,
        name: fallbackName,
        html: decoded.trim(),
      );
    }

    // 降级：整段当 HTML
    _assertLooksLikeHtml(text);
    return ParseResult(
      mode: ParseMode.html,
      name: fallbackName,
      html: text,
      warning: decoded != null ? '未识别到 JSON 中的 html 字段，已按纯 HTML 导入' : null,
    );
  }

  // ---------------------------------------------------------------- 内部

  /// 去掉 ```json ... ``` / ``` ... ``` 围栏
  static String _stripCodeFence(String raw) {
    String text = raw.trim();
    if (!text.startsWith('```')) return text;

    final int firstLineEnd = text.indexOf('\n');
    if (firstLineEnd == -1) return text;

    // 去掉首行 ```xxx
    text = text.substring(firstLineEnd + 1);
    // 去掉结尾的 ```
    final int lastFence = text.lastIndexOf('```');
    if (lastFence != -1) {
      text = text.substring(0, lastFence);
    }
    return text.trim();
  }

  /// 尝试解析成 JSON，失败返回 null
  static Object? _tryDecodeJson(String text) {
    final String head = text.trimLeft();
    final bool looksJson = head.startsWith('{') || head.startsWith('[') || head.startsWith('"');
    if (!looksJson) return null;
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  /// 按候选键名取字符串值（值必须是 String）
  static String? _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final Object? value = map[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  /// 至少要有标签特征，否则说明用户粘贴的不是 HTML
  static void _assertLooksLikeHtml(String html) {
    if (!_tagPattern.hasMatch(html)) {
      throw const ToolParseException('没有识别到 HTML 内容，请确认粘贴的是大模型返回的完整结果');
    }
  }
}

/// 全局常量：目录名、文件名、文案默认值、上限。
library;

/// 本地存储目录与文件名
class AppDirs {
  const AppDirs._();

  /// 文档目录下的根目录名
  static const String root = 'toolbox';

  /// 工具 HTML 存放目录
  static const String tools = 'tools';

  /// 工具索引（列表元信息，不含 HTML）
  static const String indexFile = 'index.json';

  /// 提示词模板
  static const String templatesFile = 'templates.json';

  /// 应用设置（当前选中工具 / 当前模板）
  static const String settingsFile = 'settings.json';

  /// 内置默认模板资源
  static const String defaultTemplatesAsset = 'assets/prompts/default_templates.json';

  static const String htmlExt = '.html';
}

/// 界面文案
class AppText {
  const AppText._();

  static const String appName = 'ToolBox';
  static const String unnamedTool = '未命名工具';

  static const String emptyTitle = '还没有工具';
  static const String emptyHint = '打开左上角 ☰ 侧边栏，点击底部的「新建工具」开始创建第一个工具。';

  static const String newTool = '新建工具';
  static const String newFirstTool = '新建第一个工具';

  static const String sidebarTitle = '工具箱';

  static const String settingsTitle = '设置';
  static const String templateSectionTitle = '提示词模板';
  static const String dataSectionTitle = '数据';

  static const String stepRequirement = '描述需求';
  static const String stepImport = '导入内容';
  static const String stepPreview = '预览应用';

  static const String requirementLabel = '你想要一个什么工具？';
  static const String requirementHint = '例如：做一个计算器，支持加减乘除、百分比和正负号';

  static const String nameLabel = '工具名称（可选，留空则自动识别）';
  static const String nameHint = '例如：计算器';

  static const String generatePrompt = '生成提示词并复制';
  static const String pasteLabel = '粘贴大模型返回的内容';
  static const String pasteHint = '把大模型返回的内容整体粘贴到这里';
  static const String previewAction = '预览效果';
  static const String applyAction = '应用并保存';
  static const String backAction = '返回修改';
  static const String cancel = '取消';
  static const String save = '保存';
  static const String delete = '删除';
  static const String next = '下一步';
  static const String back = '返回';

  static const String promptCopied = '提示词已复制到剪贴板';
  static const String savedAndApplied = '工具已保存';
  static const String backupExported = '备份已导出';
  static const String backupImported = '备份已导入';
}

/// 各类上限与超时
class AppLimits {
  const AppLimits._();

  /// 启动加载超时保护
  static const Duration startupTimeout = Duration(seconds: 6);

  /// 单个工具 HTML 的体积上限（字符数），防止粘贴进超大内容卡死
  static const int maxHtmlChars = 2 * 1024 * 1024;
}

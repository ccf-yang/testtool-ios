import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tool.dart';
import '../../providers/tool_providers.dart';
import '../../providers/ui_providers.dart';
import '../widgets/gradient_button.dart';
import 'tool_list_tile.dart';

/// 侧边栏抽屉：搜索 + 工具列表 + 底部唯一的「新建工具」入口
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.onCreateTool});

  final VoidCallback onCreateTool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final List<Tool> tools = ref.watch(filteredToolsProvider);
    final int total = ref.watch(toolListProvider).valueOrNull?.length ?? 0;
    final String query = ref.watch(searchQueryProvider);
    final double width =
        math.min(MediaQuery.of(context).size.width * 0.79, 302);

    return Drawer(
      width: width,
      backgroundColor: palette.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.horizontal(right: Radius.circular(AppRadii.sheet)),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // 标题 + 数量
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              child: Row(
                children: <Widget>[
                  Text(
                    AppText.sidebarTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      color: palette.text,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.surface3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$total 个',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: palette.text2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 搜索
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: palette.surface3,
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.search_rounded, size: 16, color: palette.text3),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (String v) =>
                            ref.read(searchQueryProvider.notifier).set(v),
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: TextStyle(fontSize: 14.5, color: palette.text),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: '搜索工具',
                          hintStyle:
                              TextStyle(fontSize: 14.5, color: palette.text3),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 列表
            Expanded(
              child: tools.isEmpty
                  ? _buildEmpty(context, total, query)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: tools.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Text(
                              '全部工具',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: palette.text3,
                              ),
                            ),
                          );
                        }
                        return ToolListTile(tool: tools[index - 1]);
                      },
                    ),
            ),

            // 底部唯一的新建入口
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.line)),
              ),
              child: GradientButton(
                label: AppText.newTool,
                icon: Icons.add_rounded,
                height: 48,
                onTap: onCreateTool,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, int total, String query) {
    final AppPalette palette = context.palette;
    final bool searching = total > 0 && query.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              searching ? Icons.search_off_rounded : Icons.inbox_rounded,
              size: 34,
              color: palette.text3,
            ),
            const SizedBox(height: 12),
            Text(
              searching ? '没有匹配的工具' : '还没有工具',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: palette.text2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searching ? '换个关键词试试' : '点击下方按钮创建第一个工具',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: palette.text3),
            ),
          ],
        ),
      ),
    );
  }
}

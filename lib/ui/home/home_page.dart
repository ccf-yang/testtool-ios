import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/tool.dart';
import '../../providers/create_flow_providers.dart';
import '../../providers/tool_providers.dart';
import '../create_tool/create_tool_sheet.dart';
import '../drawer/sidebar.dart';
import '../settings/settings_page.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_navbar.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tool_webview.dart';
import 'empty_state.dart';

/// 主页：启动后直接渲染第一个工具；新建工具入口只在侧边栏底部。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _openCreateSheet() async {
    _scaffoldKey.currentState?.closeDrawer();
    ref.read(createFlowProvider.notifier).reset();

    final Tool? created = await showModalBottomSheet<Tool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.mask,
      builder: (BuildContext _) => const CreateToolSheet(),
    );

    if (!mounted || created == null) return;
    showAppToast(context, '${AppText.savedAndApplied}：${created.displayName}');
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => const SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<Tool>> toolsAsync = ref.watch(toolListProvider);
    final Tool? current = ref.watch(currentToolProvider);
    final AsyncValue<String> htmlAsync = ref.watch(currentToolHtmlProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.bg,
      drawer: Sidebar(onCreateTool: _openCreateSheet),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              GlassNavbar(
                title: current?.displayName ?? AppText.sidebarTitle,
                leading: NavIconButton(
                  icon: Icons.menu_rounded,
                  size: 22,
                  onTap: _openDrawer,
                ),
                trailing: NavIconButton(
                  icon: Icons.settings_outlined,
                  size: 21,
                  onTap: _openSettings,
                ),
              ),
              Expanded(child: _buildBody(toolsAsync, htmlAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<List<Tool>> toolsAsync,
    AsyncValue<String> htmlAsync,
  ) {
    if (toolsAsync.isLoading && !toolsAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (toolsAsync.hasError && !toolsAsync.hasValue) {
      return _ErrorView(message: '${toolsAsync.error}');
    }

    final List<Tool> tools = toolsAsync.valueOrNull ?? const <Tool>[];
    if (tools.isEmpty) {
      return const EmptyState();
    }

    return htmlAsync.when(
      data: (String html) => html.trim().isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ToolWebView(html: html),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _ErrorView(message: '$error'),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 38, color: palette.text3),
            const SizedBox(height: 14),
            Text(
              '出错了',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.text2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

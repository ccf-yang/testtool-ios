import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/theme/app_palette.dart';

/// 用 WebView 渲染工具 HTML。
///
/// 关键点：给 `initialData` 指定一个 https 的 baseUrl，
/// 这样页面里的 localStorage / CDN 资源（图表库等）才能正常工作。
class ToolWebView extends StatefulWidget {
  const ToolWebView({super.key, required this.html});

  final String html;

  @override
  State<ToolWebView> createState() => _ToolWebViewState();
}

class _ToolWebViewState extends State<ToolWebView> {
  String? _error;

  @override
  void didUpdateWidget(covariant ToolWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    if (error != null) {
      return _WebErrorView(message: error, onRetry: () => setState(() => _error = null));
    }

    return InAppWebView(
      key: ValueKey<int>(widget.html.hashCode),
      initialData: InAppWebViewInitialData(
        data: widget.html,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://toolbox.local/'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        transparentBackground: true,
        supportZoom: false,
        disableContextMenu: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onReceivedError: (
        InAppWebViewController controller,
        WebResourceRequest request,
        WebResourceError err,
      ) {
        // 只关心主文档的错误，CDN 图片/脚本失败不影响工具本身
        if (request.isForMainFrame ?? false) {
          setState(() => _error = err.description);
        }
      },
    );
  }
}

class _WebErrorView extends StatelessWidget {
  const _WebErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 40, color: palette.text3),
            const SizedBox(height: 14),
            Text(
              '页面加载失败',
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
            const SizedBox(height: 18),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

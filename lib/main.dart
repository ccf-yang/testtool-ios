import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants.dart';
import 'data/app_paths.dart';
import 'providers/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 准备本地目录（超时保护，避免极端情况下卡在启动页）
    final AppPaths paths =
        await AppPaths.resolve().timeout(AppLimits.startupTimeout);

    runApp(
      ProviderScope(
        overrides: <Override>[
          appPathsProvider.overrideWithValue(paths),
        ],
        child: const ToolBoxApp(),
      ),
    );
  } catch (e) {
    runApp(BootErrorApp(message: '$e'));
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_paths.dart';
import '../data/repositories/backup_repository.dart';
import '../data/repositories/template_repository.dart';
import '../data/repositories/tool_repository.dart';

/// 数据根目录。必须在 `main()` 里 override（因为需要 await path_provider）。
final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider 必须在 ProviderScope 中 override'),
);

final toolRepositoryProvider = Provider<ToolRepository>(
  (ref) => ToolRepository(ref.watch(appPathsProvider)),
);

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepository(ref.watch(appPathsProvider)),
);

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => const BackupRepository(),
);

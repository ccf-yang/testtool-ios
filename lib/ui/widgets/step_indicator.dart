import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// 新建工具流程的步骤条：描述需求 → 导入内容 → 预览应用
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current});

  /// 0 / 1 / 2
  final int current;

  static const List<String> _labels = <String>[
    AppText.stepRequirement,
    AppText.stepImport,
    AppText.stepPreview,
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<Widget> children = <Widget>[];

    for (int i = 0; i < _labels.length; i++) {
      if (i > 0) {
        children.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: i <= current
                      ? AppColors.brand1
                      : palette.line2,
                ),
              ),
            ),
          ),
        );
      }
      children.add(_buildStep(context, i));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      child: Row(children: children),
    );
  }

  Widget _buildStep(BuildContext context, int index) {
    final AppPalette palette = context.palette;
    final bool done = index < current;
    final bool active = index == current;

    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active || done ? AppColors.brandGradient : null,
              color: active || done ? null : palette.surface3,
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.brand1.withAlpha(90),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : palette.text3,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            _labels[index],
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active
                  ? AppColors.brand1
                  : (done ? palette.text2 : palette.text3),
            ),
          ),
        ],
      ),
    );
  }
}

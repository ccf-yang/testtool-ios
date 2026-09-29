import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// 表单小节标题
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: palette.text2,
        ),
      ),
    );
  }
}

/// 统一风格输入框：内嵌 surface 底 + 无边框 + 大圆角
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.monospace = false,
    this.onChanged,
    this.autofocus = false,
    this.fontSize = 15.5,
    this.expands = false,
  });

  final TextEditingController controller;
  final String? hint;
  final int minLines;
  final int maxLines;
  final bool monospace;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final double fontSize;
  final bool expands;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface3,
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        minLines: expands ? null : minLines,
        maxLines: expands ? null : maxLines,
        expands: expands,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: TextStyle(
          fontSize: fontSize,
          height: monospace ? 1.7 : 1.5,
          letterSpacing: monospace ? 0 : -0.2,
          color: palette.text,
          fontFamily: monospace ? 'monospace' : null,
        ),
        cursorColor: palette == AppPalette.dark
            ? const Color(0xFFA5B4FC)
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: fontSize,
            color: palette.text3,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}

/// 提示条（浅色底 + 图标）
class AppHintCard extends StatelessWidget {
  const AppHintCard({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface3,
        borderRadius: BorderRadius.circular(AppRadii.s + 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: palette.text2),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: palette.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

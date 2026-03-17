import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';

class AppSubtitleText extends StatelessWidget {
  const AppSubtitleText({
    super.key,
    required this.label,
    this.fontSize = 14,
    this.color = AppColors.muted,
    this.maxLines,
    this.fontWeight = FontWeight.w500,
  });

  final String label;
  final double fontSize;
  final Color color;
  final int? maxLines;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }
}

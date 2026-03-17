import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';

class AppTitleText extends StatelessWidget {
  const AppTitleText({
    super.key,
    required this.label,
    this.fontSize = 22,
    this.color = AppColors.text,
  });

  final String label;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SubtitleTextWidget extends StatelessWidget {
  const SubtitleTextWidget(
      {super.key,
      required this.label,
      this.fontSize = 18,
      this.fontStyle = FontStyle.normal,
      this.fontWeight = FontWeight.normal,
      this.color,
      this.textDecoration = TextDecoration.none,
      this.maxLines});

  final String label;
  final double fontSize;
  final FontStyle fontStyle;
  final FontWeight? fontWeight;
  final Color? color;
  final TextDecoration textDecoration;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: fontSize,
        fontStyle: fontStyle,
        fontWeight: fontWeight,
        color: color,
        decoration: textDecoration,
      ),
    );
  }
}

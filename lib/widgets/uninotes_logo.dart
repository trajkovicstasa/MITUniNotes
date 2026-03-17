import 'package:flutter/material.dart';
import 'package:notes_hub/services/assets_manager.dart';

class UniNotesLogo extends StatelessWidget {
  const UniNotesLogo({
    super.key,
    this.size = 56,
    this.showWordmark = false,
    this.textColor,
  });

  final double size;
  final bool showWordmark;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        textColor ?? Theme.of(context).appBarTheme.titleTextStyle?.color;

    final icon = Image.asset(
      AssetsManager.uniNotesLogo,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!showWordmark) {
      return icon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 12),
        Text(
          "UniNotes",
          style: TextStyle(
            color: labelColor,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

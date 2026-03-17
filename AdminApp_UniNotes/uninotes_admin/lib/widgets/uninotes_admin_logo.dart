import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';

class UniNotesAdminLogo extends StatelessWidget {
  const UniNotesAdminLogo({
    super.key,
    this.size = 44,
    this.showWordmark = true,
  });

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.54,
            height: size * 0.54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.16),
            ),
          ),
          Icon(
            Icons.shield_outlined,
            color: AppColors.primary,
            size: size * 0.34,
          ),
        ],
      ),
    );

    if (!showWordmark) {
      return icon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UniNotes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

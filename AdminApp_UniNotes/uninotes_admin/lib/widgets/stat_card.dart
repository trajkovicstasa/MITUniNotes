import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 18),
            AppTitleText(label: value, fontSize: 28),
            const SizedBox(height: 6),
            const Divider(color: AppColors.border),
            const SizedBox(height: 6),
            AppSubtitleText(label: title),
          ],
        ),
      ),
    );
  }
}

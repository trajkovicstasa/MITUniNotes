import 'package:flutter/material.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitleText(label: title, fontSize: 20),
            const SizedBox(height: 6),
            AppSubtitleText(label: subtitle, maxLines: 2),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

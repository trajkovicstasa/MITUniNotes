import 'package:flutter/material.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';
import 'package:notes_hub/widgets/title_text.dart';

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
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
            TitelesTextWidget(label: title, fontSize: 20),
            const SizedBox(height: 6),
            SubtitleTextWidget(label: subtitle, maxLines: 3),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

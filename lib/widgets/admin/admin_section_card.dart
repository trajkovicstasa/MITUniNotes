import 'package:flutter/material.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';

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
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const SizedBox(height: 6),
            SubtitleTextWidget(label: subtitle),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

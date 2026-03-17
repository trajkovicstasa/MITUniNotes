import 'package:flutter/material.dart';
import 'package:notes_hub/screens/search_screen.dart';
import 'package:notes_hub/widgets/subtitle_text.dart';

class CategoryRoundedWidget extends StatelessWidget {
  const CategoryRoundedWidget({
    super.key,
    required this.image,
    required this.name,
  });

  final String image;
  final String name;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, SearchScreen.routName, arguments: name);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Image.asset(
                image,
                height: 38,
                width: 38,
              ),
            ),
            const SizedBox(height: 10),
            SubtitleTextWidget(
              label: name,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }
}

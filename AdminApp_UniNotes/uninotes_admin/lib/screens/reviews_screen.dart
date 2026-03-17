import 'package:flutter/material.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';
import 'package:uninotes_admin/widgets/section_card.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Recenzije',
        subtitle:
            'Mesto za moderaciju komentara, ocena i prijavljenog sadrzaja.',
        child: Column(
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTitleText(
                    label: 'Analiza 1 - zbirka zadataka',
                    fontSize: 17,
                  ),
                  SizedBox(height: 4),
                  AppSubtitleText(
                    label:
                        'Komentar korisnika ide ovde. Kasnije se vezuje za bazu i prijave.',
                    maxLines: 3,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

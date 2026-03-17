import 'package:flutter/material.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';
import 'package:uninotes_admin/widgets/section_card.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Kupovine',
        subtitle:
            'Pregled transakcija i kupljenih skripti. Kasnije ide PayPal i status naplate.',
        child: Column(
          children: List.generate(5, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTitleText(
                          label: 'Analiza 1 - zbirka zadataka',
                          fontSize: 17,
                        ),
                        SizedBox(height: 4),
                        AppSubtitleText(label: 'Kupac: student@uninotes.rs'),
                      ],
                    ),
                  ),
                  AppSubtitleText(
                    label: '1200 RSD',
                    fontWeight: FontWeight.w800,
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

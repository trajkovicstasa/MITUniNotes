import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';
import 'package:uninotes_admin/widgets/section_card.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Korisnici',
        subtitle: 'Pregled naloga, rola i statusa korisnika.',
        child: Column(
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTitleText(label: 'Milica Petrovic', fontSize: 17),
                        SizedBox(height: 4),
                        AppSubtitleText(label: 'milica@uninotes.rs'),
                      ],
                    ),
                  ),
                  const AppSubtitleText(
                    label: 'User',
                    fontWeight: FontWeight.w700,
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

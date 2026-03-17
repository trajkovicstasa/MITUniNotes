import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';
import 'package:uninotes_admin/screens/upload_script_screen.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/app_title_text.dart';
import 'package:uninotes_admin/widgets/section_card.dart';

class ScriptsScreen extends StatelessWidget {
  const ScriptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Skripte',
        subtitle:
            'Pregled svih skripti, filter po predmetu i statusu, plus moderacija.',
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Pretrazi po naslovu, autoru ili predmetu',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const Scaffold(
                          body: SafeArea(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: UploadScriptScreen(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Dodaj skriptu'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTitleText(
                            label: 'Analiza 1 - zbirka zadataka',
                            fontSize: 17,
                          ),
                          SizedBox(height: 4),
                          AppSubtitleText(
                            label: 'Predmet: Matematika | Autor: Korisnik',
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(label: index.isEven ? 'Pending' : 'Approved'),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isPending = label == 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isPending ? AppColors.warning : AppColors.success)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppSubtitleText(
        label: label,
        color: isPending ? AppColors.warning : AppColors.success,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

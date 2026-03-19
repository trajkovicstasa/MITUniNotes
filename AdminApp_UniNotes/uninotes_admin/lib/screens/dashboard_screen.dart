import 'package:flutter/material.dart';
import 'package:uninotes_admin/consts/app_colors.dart';
import 'package:uninotes_admin/widgets/app_subtitle_text.dart';
import 'package:uninotes_admin/widgets/section_card.dart';
import 'package:uninotes_admin/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statColumns = width >= 1280
              ? 4
              : width >= 760
              ? 2
              : 1;
          final showSectionGrid = width >= 980;
          final showStatGrid = width >= 600;

          return Column(
            children: [
              if (showStatGrid)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _stats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: statColumns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 170,
                  ),
                  itemBuilder: (context, index) => _stats[index],
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < _stats.length; i++) ...[
                      _stats[i],
                      if (i != _stats.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
              if (showSectionGrid)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sections.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 220,
                      ),
                  itemBuilder: (context, index) => _sections[index],
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < _sections.length; i++) ...[
                      _sections[i],
                      if (i != _sections.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

const List<StatCard> _stats = [
  StatCard(
    title: 'Ukupno skripti',
    value: '124',
    icon: Icons.menu_book_rounded,
    color: AppColors.primary,
  ),
  StatCard(
    title: 'Na cekanju',
    value: '18',
    icon: Icons.pending_actions_rounded,
    color: AppColors.warning,
  ),
  StatCard(
    title: 'Korisnici',
    value: '342',
    icon: Icons.group_rounded,
    color: AppColors.secondary,
  ),
  StatCard(
    title: 'Kupovine',
    value: '89',
    icon: Icons.shopping_cart_checkout_rounded,
    color: AppColors.accent,
  ),
];

const List<SectionCard> _sections = [
  SectionCard(
    title: 'Prioritetne radnje',
    subtitle: 'Najvaznije stvari koje admin treba da obradi danas.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionLine('8 skripti ceka odobrenje'),
        SizedBox(height: 10),
        _ActionLine('3 komentara su prijavljena'),
        SizedBox(height: 10),
        _ActionLine('5 korisnika ceka proveru podataka'),
      ],
    ),
  ),
  SectionCard(
    title: 'Stanje sistema',
    subtitle: 'Kratak pregled modula koje cemo kasnije vezati za bazu.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionLine('Skripte modul spreman za listing'),
        SizedBox(height: 10),
        _ActionLine('Kupovine modul spreman za transakcije'),
        SizedBox(height: 10),
        _ActionLine('Recenzije modul rezervisan za moderaciju'),
      ],
    ),
  ),
];

class _ActionLine extends StatelessWidget {
  const _ActionLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: AppSubtitleText(
            label: text,
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
